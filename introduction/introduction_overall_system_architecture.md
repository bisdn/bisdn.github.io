.. _fabric_intro:

**************
Basebox Fabric 
**************

Introduction
============
Basebox fabric (or just Basebox) is highly modular controller. Each of its components plays an important role in building an efficient OpenStack networking setup. It delivers high performance alongside scalability, high availability and seamless OpenStack integration, while retaining all the benefits of being fully programmable.

Recommended setup
=================
The fully integrated configuration takes advantage of all Basebox components.

The control plane and the logic associated with it resides within [baseboxd][baseboxd_gh]. The two are usually located on the same physical device or VM. baseboxd implements all of the standard L2 and L3 network switching and routing functionalities.

