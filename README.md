# GridSTAGE 

GridSTAGE (Spatio-Temporal Adversarial scenario GEneration) is a multivariate spatio-temporal data generation framework for simulation of adversarial scenarios in cyber-physical systems.

A thorough assessment of the impact of adversarial scenarios in the power grid and  their timely detection are critical for determining the appropriate response and steering the system back to safety.  Attacks on measurements from sensors such as Phasor Measurement Units (PMUs) or on control signals from  Automatic-Generation-Control (AGC) can mislead power system operators into taking wrong actions and, therefore, lead to catastrophic failures.  We are developing a framework that models the cyber-physical system of the power grid and generates multi-variate, spatio-temporal network data.  This data can be used to train ML models for anomaly detection and control.  We extend the MATLAB Power System Toolbox (PST) to emulate different models for load changes and cyber-attacks.  Our framework supports simulation of attacks such as ramp, step, random, time-delay and packet-loss on PMU data.  It also enables simulation of scenarios where corrupted measurements lead to erroneous control signals and propagate stability failures over an entire network. 

![Image description](images/powerdrone-intro.png)

# Tutorial
* Learn about [GridSTAGE](docs/Powerdrone_eML_2020Apr_v1.pdf)
