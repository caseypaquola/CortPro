import os
import argparse
import numpy as np
import nibabel as nib
from scipy.stats import skew, kurtosis

def load_MP(OUTPUT_DIR, SUBJECT_ID, NUM_SURFACES, hemis=['lh', 'rh']):
    MP_list = []

    for hemi in hemis:
        for n in range(1, NUM_SURFACES + 1):
            filename = os.path.join(
                OUTPUT_DIR,
                SUBJECT_ID,
                f"{SUBJECT_ID}_hemi-{hemi}_surf-fsaverage5_MP-{n}.mgh"
            )
            print(f"Loading: {filename}")
            img = nib.load(filename)
            data = np.squeeze(img.get_fdata())  # Remove singleton dimensions
            MP_list.append(data)

    # Concatenate all surfaces as columns
    MP = np.stack(MP_list, axis=1)  # shape: (depths, vertices)
    return MP

def calculate_moments(MP):
    """
    Input: microstructure profiles (MP), with cortical depths as
    rows and vertices/parcels as columns.
    
    Values (i.e. staining or imaging intensities) input must be integers.
    
    Output: mean amplitude (intensity) of profile, as well as the mean, sd, skewness and kurtosis (m1-4) 
    treating the profile as a frequency distribution.
    """
    depth_sampled = np.arange(1, MP.shape[0] + 1).reshape(-1, 1)

    # calculate amplitude (u0)
    mean_amplitude = np.mean(MP, axis=0)

    # rescale to allow for creation of histogram
    scaling_factor = 500 / MP.mean()
    MP_scaled = np.round(MP * scaling_factor).astype(int)

    u1 = np.zeros(MP.shape[1])
    u2 = np.zeros(MP.shape[1])
    u3 = np.zeros(MP.shape[1])
    u4 = np.zeros(MP.shape[1])

    for ii in range(MP.shape[1]):
        raw_data = np.repeat(depth_sampled[:, 0], MP_scaled[:, ii])
        u1[ii] = np.mean(raw_data)
        u2[ii] = np.std(raw_data, ddof=1)
        u3[ii] = skew(raw_data)
        u4[ii] = kurtosis(raw_data, fisher=False)

    MPmoments = np.vstack([mean_amplitude, u1, u2, u3, u4])
    return MPmoments



if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--output_dir", required=True)
    parser.add_argument("--subject_id", required=True)
    parser.add_argument("--num_surfaces", required=True)
    args = parser.parse_args()

    MP = load_MP(args.output_dir, args.subject_id, args.num_surfaces)
    MPmoments = calculate_moments(MP)

    # Save result
    np.savetxt(os.path.join(args.output_dir, f"{args.subject_id}_space-fsaverage5_desc-MP.csv"), MP)
    np.savetxt(os.path.join(args.output_dir, f"{args.subject_id}_space-fsaverage5_desc-MPmoments.csv"), MPmoments)
