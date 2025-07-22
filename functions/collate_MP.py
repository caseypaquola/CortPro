import os
import argparse
import numpy as np
import nibabel as nib

def compute_skewness(x):
    x = x[np.isfinite(x)]  # Optional: remove NaNs or infs
    mean = np.mean(x)
    std = np.std(x)
    skew = np.mean(((x - mean) / std)**3)
    return skew

def compute_kurtosis(x):
    x = x[np.isfinite(x)]
    mean = np.mean(x)
    std = np.std(x)
    kurt = np.mean(((x - mean) / std)**4) - 3  # excess kurtosis
    return kurt

def load_MP(OUTPUT_DIR, SUBJECT_ID, NUM_SURFACES, SURF_OUT, hemis=['L', 'R']):
    MP_rows = []

    for n in range(1, NUM_SURFACES + 1):
        row_data = []
        for hemi in hemis:
            filename = os.path.join(
                OUTPUT_DIR,
                SUBJECT_ID,
                f"{SUBJECT_ID}_hemi-{hemi}_surf-{SURF_OUT}_MP-{n}.mgh"
            )
            print(f"Loading: {filename}")
            img = nib.load(filename)
            data = np.squeeze(img.get_fdata())  # Remove singleton dims
            row_data.append(data)

        # Concatenate left and right hemisphere horizontally
        surface_row = np.concatenate(row_data)
        MP_rows.append(surface_row)
        
    # Concatenate all surfaces as columns
    MP = np.stack(MP_rows, axis=0)  # shape: (depths, vertices)
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
        u3[ii] = compute_skewness(raw_data)
        u4[ii] = compute_kurtosis(raw_data)

    MPmoments = np.vstack([mean_amplitude, u1, u2, u3, u4])
    return MPmoments



if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--output_dir", required=True)
    parser.add_argument("--subject_id", required=True)
    parser.add_argument("--num_surfaces", type=int, required=True)
    parser.add_argument("--surface_output", type=int, required=True)
    args = parser.parse_args()

    MP = load_MP(args.output_dir, args.subject_id, args.num_surfaces, args.surface_output)
    MPmoments = calculate_moments(MP)

    # Save result
    np.savetxt(os.path.join(args.output_dir, f"{args.subject_id}_space-{args.surface_output}_desc-MP.csv"), MP)
    np.savetxt(os.path.join(args.output_dir, f"{args.subject_id}_space-{args.surface_output}_desc-MPmoments.csv"), MPmoments)
