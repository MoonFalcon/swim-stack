#!/bin/bash
docker build . -t isaac/devops-practical
docker tag isaac/devops-practical:latest 100072912756.dkr.ecr.us-west-2.amazonaws.com/devops-practical:latest
docker push 100072912756.dkr.ecr.us-west-2.amazonaws.com/devops-practical:latest