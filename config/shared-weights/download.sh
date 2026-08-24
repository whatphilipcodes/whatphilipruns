#!/bin/sh
set -e

TRACKED_FILES="$(mktemp)"
trap 'rm -f "$TRACKED_FILES"' EXIT

download_if_missing() {
    local file_path="$1"
    local url="$2"
    local dir_path="$(dirname "$file_path")"

    mkdir -p "$dir_path"
    echo "$file_path" >> "$TRACKED_FILES"
    
    if [ ! -f "$file_path" ]; then
        echo "Downloading: $file_path"
        curl -L -# -o "$file_path" "$url"
    else
        echo "Skipping (already exists): $file_path"
    fi
}

echo "=== Initializing Model Weights ==="
echo "Downloading shared Weights..."

download_if_missing "/weights/embedding/tokenizer.json" "https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2/resolve/main/tokenizer.json"
download_if_missing "/weights/embedding/model.onnx" "https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2/resolve/main/onnx/model_quint8_avx2.onnx"
download_if_missing "/weights/generation/tokenizer.json" "https://huggingface.co/HuggingFaceTB/SmolLM3-3B-ONNX/resolve/main/tokenizer.json"
download_if_missing "/weights/generation/model_q4f16.onnx" "https://huggingface.co/HuggingFaceTB/SmolLM3-3B-ONNX/resolve/main/onnx/model_q4f16.onnx"
download_if_missing "/weights/generation/model_q4f16.onnx_data" "https://huggingface.co/HuggingFaceTB/SmolLM3-3B-ONNX/resolve/main/onnx/model_q4f16.onnx_data"

echo "=== Cleaning Up Orphaned Files ==="
if [ -d "/weights" ]; then
    find /weights -type f | while read -r file; do
        if ! grep -qxF "$file" "$TRACKED_FILES"; then
            echo "Removing orphaned: $file"
            rm -f "$file"
        fi
    done
    find /weights -type d -empty -delete
fi

echo "=== Downloads Complete ==="