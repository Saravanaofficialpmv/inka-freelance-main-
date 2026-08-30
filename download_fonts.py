import urllib.request
import os
import zipfile

def download_and_extract():
    base_dir = "/Users/saravana/flutter/final clg management application/invoice generator/invoice_generator"
    os.makedirs(f"{base_dir}/assets/fonts/Inter", exist_ok=True)
    os.makedirs(f"{base_dir}/assets/fonts/Poppins", exist_ok=True)
    
    # Download Poppins
    poppins_urls = {
        f"{base_dir}/assets/fonts/Poppins/Poppins-Regular.ttf": "https://raw.githubusercontent.com/google/fonts/main/ofl/poppins/Poppins-Regular.ttf",
        f"{base_dir}/assets/fonts/Poppins/Poppins-Medium.ttf": "https://raw.githubusercontent.com/google/fonts/main/ofl/poppins/Poppins-Medium.ttf",
        f"{base_dir}/assets/fonts/Poppins/Poppins-Bold.ttf": "https://raw.githubusercontent.com/google/fonts/main/ofl/poppins/Poppins-Bold.ttf",
    }
    
    for k, v in poppins_urls.items():
        print(f"Downloading {v}...")
        urllib.request.urlretrieve(v, k)
    
    # Download Inter via the release zip
    inter_zip_url = "https://github.com/rsms/inter/releases/download/v4.0/Inter-4.0.zip"
    inter_zip_path = "/tmp/inter.zip"
    print(f"Downloading {inter_zip_url}...")
    
    req = urllib.request.Request(inter_zip_url, headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req) as response, open(inter_zip_path, 'wb') as out_file:
        out_file.write(response.read())
        
    print("Extracting Inter zip...")
    with zipfile.ZipFile(inter_zip_path, 'r') as zip_ref:
        for info in zip_ref.infolist():
            if info.filename.endswith('ttf'):
                print(f"Found ttf: {info.filename}")
                if 'extras/ttf/Inter-Regular.ttf' in info.filename:
                    zip_ref.extract(info, '/tmp/inter_extract')
                elif 'extras/ttf/Inter-Medium.ttf' in info.filename:
                    zip_ref.extract(info, '/tmp/inter_extract')
                elif 'extras/ttf/Inter-Bold.ttf' in info.filename:
                    zip_ref.extract(info, '/tmp/inter_extract')

    os.rename("/tmp/inter_extract/extras/ttf/Inter-Regular.ttf", f"{base_dir}/assets/fonts/Inter/Inter-Regular.ttf")
    os.rename("/tmp/inter_extract/extras/ttf/Inter-Medium.ttf", f"{base_dir}/assets/fonts/Inter/Inter-Medium.ttf")
    os.rename("/tmp/inter_extract/extras/ttf/Inter-Bold.ttf", f"{base_dir}/assets/fonts/Inter/Inter-Bold.ttf")

    print("Done")

if __name__ == "__main__":
    download_and_extract()
