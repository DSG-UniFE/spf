# SPF

SPF (as in "Sieve, Process, and Forward") is a Software-Defined Networking
(SDN) and Value-of-Information (VoI) based solution for dynamic IoT
applications in urban computing environments.

SPF aims to address the explosion of IoT data by processing it at the edge of
the network, in close proximity to the source of its generation. In order to
filter information objects, SPF uses a minimum content difference threshold for
new IoT data to be considered for processing and dissemination. In addition,
SPF prioritizes dissemination of critical information by ranking objects
according to their corresponding VoI metric.


## Stakeholders

We envision 3 roles for the stakeholders in the SPF architecture:
administrators, service providers, and users. Administrators manage the SPF
platform by deploying, running, and operating SPF controllers and Programmable
IoT Gateways (PIGs), and making them available to service providers. Service
providers develop IoT applications, deploy them, and take care of their
management. Finally, users are people who use SPF applications through a client
app on their smart devices. In our example, users of the SPF are participants,
the EMS, and the police force. We can imagine that the management and service
provider roles in this scenario would be played by two corresponding commercial
companies.


## Android Client

SPF users can access the services offered by the platform through an Android
client App, which is available [here](https://github.com/gentiliniluca/AndroidApp).


## Information processing pipelines

At the moment, SPF supports an image processing pipeline, which leverages the
well known OpenCV and Tesseract software components. The source code is
available [here](https://github.com/gentiliniluca/Pipeline_SPF).
