BIRDSEYE DESIGN GOALS
------------

The following design goals were used in the development of Birdseye to guide
how it has been developed in the past and steer it forward in the future.

Hopefully, this list will help answer questions about why Birdseye exists in
such a form and not implemented differently.

* **A single file bash script.**

  You should be able to *easily* copy a single file to a sensitive or 
  unhealthy system, run it, and remove it quickly and easily.

* **Zero required dependencies.**

  You should be able to run Birdseye with a single file and not *require* adding
  additional software packages or components to the system you are reporting
  upon.  This minimizes the impact of running Birdseye on the system so that
  its natural state and not its state after being influenced by Birdseye.
	Additional packages may be called, but not *required*.

* **Output using HTML5 for structure and CSS3 for presentation**

  You should be able to use your own CSS to easily modify Birdseye report
  presentations to satisfy your needs without modifying the bash scripting
  that reports on your system.

* **Compatible with Linux on bare-metal, virtual machine (guests) and Cloud Linux**

  You should be able to run Birdseye on any relatively mainstream Linux and
  on any relatively mainstream operating environment.  We will regularly test
  on bare-metal desktops and servers, KVM and Xen guest VMs and common commercial
  Cloud guest VM environments.  Embedded systems and specialty systems are not 
  the focus of Birdseye.

* **Compatible with multiple Linux distributions**

  You should be able to run Birdseye on many mainstream Linux environments.
  See the supported/testing document for details.

* **Develop code that is simple, literal and well documented**

  You should be able to easily read the Birdseye code and understand what it
  is doing.  This allows you to modify it easily. It also allows many others
  to use Birdseye as a tutorial on various commands found within Linux.
  Write code for others and try not to be too clever.
