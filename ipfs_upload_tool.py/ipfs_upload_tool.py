import os
import json
import requests

# Set your NFT.storage API key here
API_KEY = "YOUR_NFT_STORAGE_API_KEY"  # <-- Replace with your actual API key

# Folder containing JSON files to upload
FOLDER_PATH = "./verifyvault_ipfs_metadata"  # <-- Replace with your folder path

def upload_to_nft_storage(file_path):
    headers = {
        "Authorization": f"Bearer {API_KEY}"
    }
    with open(file_path, 'rb') as f:
        files = {
            'file': (os.path.basename(file_path), f),
        }
        response = requests.post("https://api.nft.storage/upload", headers=headers, files=files)
        if response.ok:
            cid = response.json()['value']['cid']
            print(f"Uploaded {file_path} → CID: {cid}")
            return cid
        else:
            print(f"Failed to upload {file_path}: {response.text}")
            return None

def batch_upload(folder_path):
    cids = {}
    # Sort files by numeric prefix before the extension (e.g., 1.json, 2.json)
    for filename in sorted(os.listdir(folder_path), key=lambda x: int(os.path.splitext(x)[0])):
        if filename.endswith(".json"):
            path = os.path.join(folder_path, filename)
            cid = upload_to_nft_storage(path)
            if cid:
                cids[filename] = cid
    # Save the mapping of filenames to CIDs
    with open("uploaded_cids.json", "w") as f:
        json.dump(cids, f, indent=2)
    print("Upload complete. CID map saved to uploaded_cids.json.")

if __name__ == "__main__":
    batch_upload(FOLDER_PATH)