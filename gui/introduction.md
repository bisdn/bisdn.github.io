# Basebox GUI

Designed for the simplicity of configuration and visualization, Basebox's GUI provides a clear interface for all of the currently supported commands. This means interaction with the setup is possible via this web interface,
on a fast and responsive system.

## Configuration

``basebox-gui`` is managed by systemd, so the standard systemctl commands apply to this application.
Configuration file is (where X is your python3 version):

```
/usr/lib/python3.X/site-packages/gui/settings.py
```

In the settings file you can find a couple of variables that you can setup to point the endpoints to the correct place. These are

```
BASEBOX_API_IP = 'localhost'
BASEBOX_API_PORT = 50051

# GRPC settings
GRPC_CAWR_SERVER_IP = 'localhost'
GRPC_CAWR_SERVER_PORT = 5001

GRPC_BASEBOXD_SERVER_IP = 'localhost'
GRPC_BASEBOXD_SERVER_PORT = 5000

GRPC_TIMEOUT_SEC = 2
```

## Accessing

You can access this service via ``http://<controller address>:8000``.

# Views

When you start the GUI via the previously indicated address, you can see this view.

![GUI Main view][main_view]

Here is present the components status, providing information about the additional Basebox services, including their address and operational state. In the sidebar, under the main navigation section you see the views from the
controllers, baseboxd and CAWR.

Clicking the links to baseboxd view and CAWR view will point to the following views.

## baseboxd View

This view presents the information that baseboxd reports. In the main window the topology from the single-switch (or single-switch abstraction, using CAWR) is visible. The switch ports can be visible by clicking on the icon for the 
switch. Each switch port has the information about traffic statistics, configured VLANs and IP addresses. 

## CAWR View 

The view from CAWR displays the physical topology configured, with the servers, switches, and connections between them. In the links between the servers and switches there is mapping between physical switch port and the 
ports on the physical servers.

[main_view]: ../images/gui_main_view.png
