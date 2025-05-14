## EMLOV4-Session-18 Capstone Assignment - Canary Deployment

### Contents

- [Requirements](#requirements)
- [Development Method](#development-method)
    - [Installation](#installation)
        - [HF models and torchserve files setup](#hf-models-and-torchserve-files-setup)
        - [Cluster creation and configuration](#cluster-creation-and-configuration)
        - [ArgoCD and Canary Deployment](#argocd-and-canary-deployment)
        - [Deletion Procedure](#deletion-procedure)
    - [Deplpyment 01]
    - [Deployment 02]
    - [Deployment 03]
- [Learnings](#learnings)
- [Results Screenshots](#results-screenshots)

### Requirements
1. On Pull Request to the main branch:
- Trigger a model training process (using EC2 or GitHub Actions Runner).
- Compare the evaluation metrics of the freshly trained model with those of the current production model.

2. On Push to the main branch:
- Retrain the model using the latest dataset.
- Store the updated model in S3. - stage - env
- Update Kubernetes manifest files to reference the new model. - stage
- You can manipulate yaml files using python and push to some new branch
- ArgoCD can listen to this new branch
- Roll out the model to production via ArgoCD.
- Run a stress test to log latency and throughput.
- These can be added as comment to the commit
- Deploy updates to the HuggingFace Hub demo deployment
- Deploy to AWS Lambda as an additional serving endpoint.
might not be required if you’re pulling the model from S3

To successfully complete the capstone project, you must submit:

- A comprehensive architecture diagram illustrating the entire pipeline and deployment process.
- A demonstration video that walks through the end-to-end pipeline, showing each step and its impact.
- The complete code repository containing:
GitHub Actions configuration files.
Kubernetes manifest files and Helm charts.
- An exhaustive README that details:
- The project's structure.
- The process of data management, model training, and deployment.
- Screenshots and explanations of your pipeline in action.
Performance metrics, including latency and stress test results.

### Pending for Deployment 1
Code
- Torchserve not giving proper predictions even for true class, check it - look later - check if its the preprocessing issue
- Transfer_mar should transfer .pt file and accuracy text file to s3. it can be used for gradio, lambda and accuracy checking
- Update Workflow to train on pull request and store to s3-dev and compare with prod model accuracy and comment in github actions
- Update Workflow to train on push request and store to s3-stage for deployment
- After stress test move from stage to prod 
- Comment on the commit with cml for stress test results

Docs
- Architecture diagram
- Screenshots of deployment and video

### Development Method
**Download Dataset**
```bash
chmod +x shscripts/download_zips.sh && ./shscripts/download_zips.sh
```
**Sports**
```bash
data/processed/sports/
├── sports.csv
├── test
│   ├── air hockey
│   ├── .
│   ├── .
│   ├── .
│   └── wingsuit flying
├── train
│   ├── air hockey
│   ├── .
│   ├── .
│   ├── .
│   └── wingsuit flying
└── valid
    ├── air hockey
    ├── .
    ├── .
    ├── .
    └── wingsuit flying
-----------------------------------------------------
data/processed/vegfruits/
```


**Install Dependencies**
```bash
uv sync --extra cpu   # install torch-cpu version
uv sync --extra cu124 # install torch-gpu version  cu124
uv sync --group develop --group visuals --group testing --group prod --extra cpu
uv sync --group develop --group visuals --group testing --group prod --extra cu124   # install deps from all
uv run --env-file .env --extra cpu
```

**Model Development Phase**
**Hparams Search**

```bash
make hsports   # make sure comment that pretrained model and run longer epoch & max to n_trails
```
```yaml
experiment: hsports
hydra:
    sweeper:
        n_trails: 26  # variation of models
    params:
      ++model.stem_type: choice('patch','overlap')
      ++model.act_layer: choice('relu','gelu')
      ++model.global_pool: choice('avg','fast')
      ++model.depths: "[2,2,6,2],[3,3,9,3]"
      ++model.dims: "[24,48,22,168],[12,32,44,96]"
      ++model.kernel_sizes: "[3, 5, 7, 9],[3,3,3,3]"
      ++model.use_pos_emb: "[False,True,False,False], [True,True,True,False]"
trainer:
    max_epochs: 10
```
## Train Model
```yaml
experiment: tsports
script: true
name: sports
callbacks.model_checkpoint.filename: sports
```

```bash
make tsports   # uncomment the pretrained model to save time.
```
**Evaluate Model**
- [X] Check Test Metrics
- [X] Save Models
    - [X] checkpoints
    - [X] torchscript
        - [X] cpu
        - [X] gpu
    - [X] onnx
- [X] Explore Dataset
    - [X] Class Distribution
    - [X] Batch Images
- [X] Condusion Matrixs
    - [X] Train
    - [X] Test
    - [X] Validation


**Gradio Locally**
```bash
make gsports
open http://0.0.0.0:7860/
```


**TorchServe Locally**

```bash
export ENABLE_TORCH_PROFILER=true
```
```properties
enable_envvars_config=true
```


```bash
torch-model-archiver  \
    --model-name sports \
    --version 1.0  \
    --export-path ./model_stores/mar_sports \
    --hander  ./src/backend/torchserve_app/sports_handler.py  \
    --serialized-file ./checkpoints/pths/sports.pt \
    --extra-files index_to_name.json \

```

**Torchserve - Preparation file**

```
    torch-model-archiver --model-name {project}-classifier
    --serialized-file {deploy_dir}/{project}.onnx
    --handler src/backend/torchserve_app/{project}_handler.py
    --export-path {deploy_dir}/model-store/ -f --version 0.0.1
    --extra-files {deploy_dir}/index_to_name.json
```


**ON Docker** 

```bash
# github.com/moby/moby/issues/12886#issuecomment-480575928
export DOCKER_BUILDKIT=1
```

#### Usage for deployment (in local)

Basic train

- `uv run python src/backend/torch_local/train.py experiment=hvegfruits script=true`
- `uv run python src/backend/torch_local/train.py experiment=hsports script=true`

scripts takes care of creating onnx model in checkpoints folder

Eval

- `uv run python src/backend/torch_local/eval.py experiment=evegfruits`
- `uv run python src/backend/torch_local/eval.py experiment=esports`

Take the model and host it with fast api

- host one api in 8080 and another api in 9090

- `uv run python src/backend/fastapi_app/fapi_vegfruits.py` 
- `uv run python src/backend/fastapi_app/fapi_sports.py` 

Move files to s3

- `python src/backend/torch_local/transfer_mar.py `

**Next JS**
There are two choosing buttons and each one redirects to different end points
- End points can be changed in `src/frontend/ui/app/predict_app1` and `src/frontend/ui/app/predict_app2`

- npm run dev



### DVC setup

make sure data/processed {sports, vegfruits} are present

dvc remote add -d myremote s3://mybucket-emlo-mumbai/session-18-data
dvc add data
dvc push -r myremote

### Docker command

to train

docker run --gpus=all \
            --name session-18-container \
            -v "$(pwd):/workspace" \
            -e AWS_ACCESS_KEY_ID=AWS_ACCESS_KEY_ID \
            -e AWS_SECRET_ACCESS_KEY=AWS_SECRET_ACCESS_KEY+AWS_SECRET_ACCESS_KEY \
            -e AWS_DEFAULT_REGION=AWS_DEFAULT_REGION \
            -e AWS_REGION=AWS_REGION \
            emlo-18-train  \
            /bin/bash -c "
              dvc pull -r myremote && \
              dvc repro -f
            "

docker run -it --gpus=all \
            --name session-18-container \
            --shm-size=8g \
            -v "$(pwd):/workspace" \
            -e AWS_ACCESS_KEY_ID=AWS_ACCESS_KEY_ID \
            -e AWS_SECRET_ACCESS_KEY=AWS_SECRET_ACCESS_KEY \
            -e AWS_DEFAULT_REGION=AWS_REGION \
            -e AWS_REGION=AWS_REGION \
            emlo-18-train  \
            /bin/bash 

## Main Technologies

[PyTorch Lightning](https://github.com/PyTorchLightning/pytorch-lightning) - a lightweight PyTorch wrapper for high-performance AI research. Think of it as a framework for organizing your PyTorch code.

[Hydra](https://github.com/facebookresearch/hydra) - a framework for elegantly configuring complex applications. The key feature is the ability to dynamically create a hierarchical configuration by composition and override it through config files and the command line.

[DVC](https://dvc.org/) - A tool designed to handle large datasets and machine learning models in a version-controlled workflow

[Tensorboard|wandb](https://www.tensorflow.org/tensorboard) - TensorBoard is a tool that provides visualization and debugging capabilities for TensorFlow and PyTorch experiments. It’s a popular choice for monitoring machine learning training processes in real time.

[AWS|EC2|S3|Lambda|ECR](https://aws.amazon.com/ec2/) - AWS Elastic Compute Cloud (EC2) is a service that provides scalable virtual computing resources in the cloud.

[Docker](https://www.docker.com/) - A platform for creating, deploying, and managing lightweight, portable, and scalable containers.

[FastAPI|Gradio](https://www.gradio.app/) - A Python library for building simple, interactive web interfaces for machine learning models and APIs.

[Nextjs]() - Frontend FrameWork

[K8s|KNative|Kserve|Istio|ArgoCD]() - AWS Kubernets and ArgoCD 

[Prometheus|Grafana] - observability


[![license](https://img.shields.io/badge/License-MIT-green.svg?labelColor=gray)](https://github.com/ashleve/lightning-hydra-template#license)