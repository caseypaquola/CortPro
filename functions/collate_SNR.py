import os
import argparse
import numpy as np
import nibabel as nib

def load_MP(OUTPUT_DIR, SUBJECT_ID, NUM_SURFACES, SURF_OUT, hemis=['L', 'R']):
    MP_rows = []

    for n in range(1, NUM_SURFACES + 1):
        row_data = []
        for hemi in hemis:
            # Construct the base path without extension
            base_path = os.path.join(
                OUTPUT_DIR,
                SUBJECT_ID,
                f"{SUBJECT_ID}_hemi-{hemi}_surf-{SURF_OUT}_SNR-{n}"
            )
            
            # Check for .mgh first, then .shape.gii
            if os.path.exists(f"{base_path}.mgh"):
                filename = f"{base_path}.mgh"
            elif os.path.exists(f"{base_path}.shape.gii"):
                filename = f"{base_path}.shape.gii"
            else:
                raise FileNotFoundError(f"Could not find .mgh or .shape.gii for {base_path}")

            print(f"Loading: {filename}")
            img = nib.load(filename)
            
            # nibabel loads GIFTI data into a list of arrays; we take the first
            if filename.endswith('.gii'):
                data = img.agg_data()
            else:
                data = np.squeeze(img.get_fdata())
                
            row_data.append(data)

        # Concatenate left and right hemisphere horizontally
        surface_row = np.concatenate(row_data)
        MP_rows.append(surface_row)
        
    # Concatenate all surfaces as columns
    MP = np.stack(MP_rows, axis=0)  # shape: (depths, vertices)
    return MP

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--output_dir", required=True)
    parser.add_argument("--subject_id", required=True)
    parser.add_argument("--num_surfaces", type=int, required=True)
    parser.add_argument("--surface_output", required=True)
    args = parser.parse_args()

    MP = load_MP(args.output_dir, args.subject_id, args.num_surfaces, args.surface_output)
    mean_amplitude = np.mean(MP, axis=0)

    # Save result
    np.savetxt(os.path.join(args.output_dir, f"{args.subject_id}_space-{args.surface_output}_desc-SNR_depths.csv"), MP)
    np.savetxt(os.path.join(args.output_dir, f"{args.subject_id}_space-{args.surface_output}_desc-SNR_average.csv"), mean_amplitude)
