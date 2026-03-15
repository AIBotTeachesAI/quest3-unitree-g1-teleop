# X-G1

**X-G1** is a rapid-iteration humanoid robotics pipeline built during a
**2-day hackathon** using the **Unitree G1**.\
Our goal was to create a workflow that moves quickly from **human
teleoperation → dataset creation → model fine-tuning → autonomous policy
evaluation**.

By combining immersive teleoperation with scalable data infrastructure
and embodied AI models, we demonstrate a **fast-track workflow for
humanoid robot learning**.

------------------------------------------------------------------------

## Project Overview

In this project we built a complete pipeline for training and evaluating
policies on the **Unitree G1 humanoid robot**.

The workflow includes:

1.  Teleoperation\
2.  Data storage & streaming\
3.  Policy fine-tuning\
4.  Diagnostics & failure analysis

This allows rapid experimentation with manipulation and locomotion tasks
such as:

-   Walking to tables
-   Beverage organization
-   Apple pick-and-place

------------------------------------------------------------------------

## System Architecture

    Meta Quest 3 Teleoperation
            │
            ▼
    MuJoCo Simulation + NVIDIA Sonic
            │
            ▼
    Demonstration Data Collection
            │
            ▼
    DeepLake Dataset Storage
            │
            ▼
    GR00T Policy Fine-tuning
            │
            ▼
    Autonomous Policy Evaluation
            │
            ▼
    Nomadic AI Diagnostics

------------------------------------------------------------------------

## Technical Implementation

### Teleoperation

We integrated **Meta Quest 3** with **MuJoCo** using **NVIDIA Sonic** to
enable **low-latency humanoid control**.

This setup allowed us to manually complete complex tasks including:

-   Navigating the robot toward tables
-   Picking and placing beverages
-   Manipulating apples

The teleoperation pipeline enables fast demonstration collection for
downstream training.

Teleop implementation:\
https://github.com/AIBotTeachesAI/quest3-g1-teleop

------------------------------------------------------------------------

### Data Strategy (DeepLake)

To support fast training iteration, we used **DeepLake** for dataset
storage and streaming.

We leveraged **Lightwheel's G1 beverage organization dataset**, storing
the data in an optimized tensor format to enable:

-   Fast random access
-   Efficient streaming
-   High-throughput training

This was critical for enabling model fine-tuning within the time
constraints of the hackathon.

Data processing pipeline:\
https://github.com/sl628/g1_hackathon/tree/main/data_processing

------------------------------------------------------------------------

### Policy Fine-Tuning (NVIDIA GR00T)

We fine-tuned **NVIDIA GR00T N1.6** using the collected teleoperation
data.

Because **Sonic's fine-tuning features are not yet released**, we used:

-   **Sonic** → high-fidelity teleoperation and data collection
-   **GR00T** → autonomous policy inference

Fine-tuning reference implementation:\
https://github.com/NVIDIA/Isaac-GR00T/tree/main/examples/GR00T-WholeBodyControl

------------------------------------------------------------------------

### Diagnostics with Nomadic

To better understand policy failures, we integrated **Nomadic AI** as a
diagnostic layer.

This allowed us to:

-   Analyze incorrect task executions
-   Inspect model reasoning
-   Identify failure modes in task instructions

These insights help guide future improvements in policy robustness.

------------------------------------------------------------------------

## Key Contributions

-   Rapid **teleop → training → evaluation** pipeline for humanoid
    robots
-   Integration of **VR teleoperation with MuJoCo simulation**
-   Efficient humanoid dataset handling using **DeepLake**
-   **GR00T-based policy fine-tuning**
-   **Nomadic AI diagnostics** for model reasoning analysis

------------------------------------------------------------------------

## Future Work

-   Deploy policies directly on **Unitree G1 hardware**
-   Expand demonstrations for broader manipulation tasks
-   Integrate **VLM-based instruction interfaces**
-   Improve policy robustness through larger datasets

------------------------------------------------------------------------

## Team

**Team Name:** X-G1\
Hackathon Project (2 days)

------------------------------------------------------------------------

## Acknowledgements

We thank the teams behind:

-   Unitree G1
-   NVIDIA GR00T
-   NVIDIA Sonic
-   Lightwheel Robotics
-   DeepLake
-   Nomadic AI

for providing the tools that made this project possible.
