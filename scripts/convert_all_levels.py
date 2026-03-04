import os
import subprocess
import glob
import logging

logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
logger = logging.getLogger(__name__)

def main():
    # Find all JSON files in the root directory
    json_files = glob.glob("*.json")
    
    if not json_files:
        logger.info("No JSON level files found in root.")
        return

    script_path = os.path.join("scripts", "json_to_tres.py")
    
    for json_file in json_files:
        logger.info(f"Converting {json_file}...")
        try:
            # Run the conversion script for each JSON file
            subprocess.run(["python", script_path, "--input", json_file], check=True)
        except subprocess.CalledProcessError as e:
            logger.error(f"Failed to convert {json_file}: {e}")
        except Exception as e:
            logger.error(f"An error occurred while processing {json_file}: {e}")

if __name__ == "__main__":
    main()
