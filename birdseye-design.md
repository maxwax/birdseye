BIRDSEYE DESIGN GOALS
------------

The following design goals are used to guide future development:

These should also help explain why Birdseye is implemented in its current form.

* **A single file bash script.**

  You should be able to *easily* copy a single file to a sensitive or 
  unhealthy system, run it, and remove it quickly and easily.

* **Zero required dependencies.**

  You should be able to run Birdseye without the requirement of additional
  packages or components. This ensures that adding Birdseye to a system
  changes its existing state as little as possible.  The Birdseye report that
  results reflects the pre-Birdseye state of the system.

  Birdseye will attempt to use the features of many optional packages, 
  but skip them if they are unavailable.
	
* **Output using HTML5 for structure and CSS3 for presentation**

  You should be able to use your own CSS to easily modify Birdseye report
  presentations to satisfy your needs without modifying the bash scripting
  that reports on your system.

* **Compatible with Linux on bare-metal, virtual machine (guests) and Cloud Linux**

  You should be able to run Birdseye on any relatively mainstream Linux and
  on any relatively mainstream operating environment.  Birdseye will be tested
  on bare-metal desktops and servers, KVM and Xen guest VMs and common commercial
  Cloud guest VM environments.  Embedded systems and specialty systems are not 
  the focus of Birdseye.

* **Compatible with multiple Linux distributions**

  You should be able to run Birdseye on many mainstream Linux environments.
  Multi-distribution support adds flexibility and prevents a focus on one
  distribution, but supporting non-mainstream distributions is not a goal.

  See the supported/testing document for details.

* **Develop code that is simple, literal and well documented**

  You should be able to easily read the Birdseye code and understand what it
  is doing.  This allows you to modify it easily. It also allows many others
  to use Birdseye as a tutorial on various commands found within Linux.
  ...Write code for others and try not to be too clever.
