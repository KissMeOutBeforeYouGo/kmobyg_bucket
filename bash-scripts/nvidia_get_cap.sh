#/bin/bash

####################
# Andrey Fomin <andreyafomin@icloud.com>
####################
# This script is used to convert ML models so they can be executed
# on single host with multiple GPUs that have different CC (Compute Capabilities).
# It's assumed that Nvidia GPUs from one generation (RXT20, RTX30 etc) have the same CC.
# Output file for each CC looks like:
#
# <filename>.<extension>.<cc>
# 
# The structure and content of model-links.json is not relevant and given as an example (and something that I use from time to time),
# so there is no file or template included.
#
# This script depends on:
# (1) Nvidia GPU Driver and CUDA libraries
# (2) TensorRT GA (for trtexec command)
# (3) Tritonserver (libraries)
# (4) jq if you

MODELS_VOLUME_DIR=/models
MODELS_LINK_FILE=$PWD/model-links.json
available_computes=$(nvidia-smi --query-gpu=index,compute_cap,gpu_name --format=csv | tail -n +2 | tr -d ' ')
num_of_models=$(jq '.models | length' $MODELS_LINK_FILE)

declare -A compute_cap

for i in $available_computes; do
	device_id=$(echo $i | awk -F[","] '{print $1}')
	device_compute_cap=$(echo $i | awk -F[","] '{print $2}')
	device_name=$(echo $i | awk -F[","] '{print $3}')
	printf "\ndevice_$device_id ($device_name) compute capability is $device_compute_cap"
	
	compute_cap[$device_compute_cap]=$device_id
done

for i in ${!compute_cap[@]}; do
	printf "\ndevice_${compute_cap[$i]} will be selected as converter for compute capabilities $i"
done

printf "\n"



for ((i=0;i<$num_of_models;++i)) do
	
	# Setting up envvars from json file
	MODEL_NAME=$(jq -r .models[$i].model_name $MODELS_LINK_FILE)
	MODEL_LINK=$(jq -r .models[$i].link $MODELS_LINK_FILE)
    MODEL_FILENAME=$(jq -r .models[$i].filename $MODELS_LINK_FILE)
    MODEL_NEEDS_CONVERT=$(jq -r .models[$i].needs_convert $MODELS_LINK_FILE)
    MODEL_FOLDER=$MODELS_VOLUME_DIR/$MODEL_NAME/1
	
	if $MODEL_NEEDS_CONVERT; then
		
		MODEL_CONVERT_OUTPUT=$(jq -r .models[$i].convert_output $MODELS_LINK_FILE)
        MODEL_CONVERT_ARGS=$(jq -r .models[$i].convert_args $MODELS_LINK_FILE)
		
		for compute in ${!compute_cap[@]}; do
			cmp=$(echo $compute | tr -d ".")
			# Note that:
			# (1) printf is the most supreme form of debugging
			# (2) don't forget to remove prinf wrapper if you want this script to do anything useful
			printf "trtexec --device=${compute_cap[$compute]} --onnx=$MODEL_FOLDER/$MODEL_FILENAME --saveEngine=$MODEL_FOLDER/$MODEL_CONVERT_OUTPUT.$cmp $MODEL_CONVERT_ARGS\n"
		done
	fi
done
