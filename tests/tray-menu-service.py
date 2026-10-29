#!/usr/bin/python3
"""Synthetic StatusNotifierItem and DBusMenu; run only on a disposable bus."""
import dbus
import dbus.service
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib

DBusGMainLoop(set_as_default=True)
bus = dbus.SessionBus()
name = dbus.service.BusName('org.example.TrayFixture', bus)

class Item(dbus.service.Object):
    @dbus.service.method('org.freedesktop.DBus.Properties', in_signature='s', out_signature='a{sv}')
    def GetAll(self, interface):
        return {'Category': 'ApplicationStatus', 'Id': 'fixture', 'Title': 'Fixture',
                'Status': 'Active', 'IconName': 'application-x-executable',
                'ItemIsMenu': True, 'Menu': dbus.ObjectPath('/Menu')}

    @dbus.service.method('org.freedesktop.DBus.Properties', in_signature='ss', out_signature='v')
    def Get(self, interface, prop):
        return self.GetAll(interface)[prop]

    @dbus.service.method('org.kde.StatusNotifierItem', in_signature='ii', out_signature='')
    def Activate(self, x, y):
        pass

class Menu(dbus.service.Object):
    submenu_present = True
    submenu_opens = 0

    @dbus.service.signal('com.canonical.dbusmenu', signature='ui')
    def LayoutUpdated(self, revision, parent):
        pass

    def remove_submenu(self):
        self.submenu_present = False
        self.LayoutUpdated(dbus.UInt32(2), dbus.Int32(0))
        print('REMOVED submenu', flush=True)
        return False

    @dbus.service.method('org.freedesktop.DBus.Properties', in_signature='s', out_signature='a{sv}')
    def GetAll(self, interface):
        return {'Version': dbus.UInt32(3), 'TextDirection': 'ltr', 'Status': 'normal', 'IconThemePath': dbus.Array([], signature='s')}

    @dbus.service.method('com.canonical.dbusmenu', in_signature='iias', out_signature='u(ia{sv}av)')
    def GetLayout(self, parent, depth, properties):
        def node(i, props, children=()):
            return dbus.Struct((dbus.Int32(i), dbus.Dictionary(props, signature='sv'), dbus.Array(children, signature='v')), signature='ia{sv}av')
        leaf = node(2, {'label': 'Nested action', 'enabled': True})
        submenu = node(1, {'label': 'Submenu', 'children-display': 'submenu'}, [leaf] if depth != 1 else [])
        disabled = node(3, {'label': 'Disabled', 'enabled': False})
        separator = node(4, {'type': 'separator'})
        entries = [disabled, separator] + ([submenu] if self.submenu_present else [])
        root = node(0, {}, entries if depth != 0 else [])
        return (dbus.UInt32(1 if self.submenu_present else 2), {0: root, 1: submenu, 2: leaf, 3: disabled, 4: separator}[parent])

    @dbus.service.method('com.canonical.dbusmenu', in_signature='i', out_signature='b')
    def AboutToShow(self, item):
        print('ABOUT', item, flush=True)
        return False

    @dbus.service.method('com.canonical.dbusmenu', in_signature='isvu', out_signature='')
    def Event(self, item, event, data, timestamp):
        print('EVENT', item, event, flush=True)
        if item == 1 and event == 'opened':
            self.submenu_opens += 1
            if self.submenu_opens == 3:
                GLib.timeout_add(100, self.remove_submenu)

item = Item(bus, '/StatusNotifierItem')
menu = Menu(bus, '/Menu')

def register():
    try:
        watcher = bus.get_object('org.kde.StatusNotifierWatcher', '/StatusNotifierWatcher')
        watcher.RegisterStatusNotifierItem('org.example.TrayFixture', dbus_interface='org.kde.StatusNotifierWatcher')
        print('REGISTERED', flush=True)
        return False
    except dbus.DBusException:
        return True

GLib.timeout_add(100, register)
GLib.MainLoop().run()
