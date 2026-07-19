#!/bin/bash

mkdir -p /workspace/hf_cache /workspace/tmp

# Bygg pytorch3d och installera till /workspace om det inte redan finns
if ! python -c "import pytorch3d" 2>/dev/null; then
    if [ -d "/workspace/pytorch3d_wheel" ]; then
        echo "Installerar pytorch3d från sparad wheel..."
        pip install --no-index --find-links=/workspace/pytorch3d_wheel pytorch3d
    else
        echo "Bygger pytorch3d från source (tar ~15 min)..."
        mkdir -p /workspace/pytorch3d_wheel
        FORCE_CUDA=1 pip wheel --no-cache-dir --no-build-isolation \
            "git+https://github.com/facebookresearch/pytorch3d.git@stable" \
            -w /workspace/pytorch3d_wheel
        pip install --no-index --find-links=/workspace/pytorch3d_wheel pytorch3d
        echo "pytorch3d sparad till /workspace/pytorch3d_wheel"
    fi
fi

# Starta Jupyter
jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --NotebookApp.token=''
