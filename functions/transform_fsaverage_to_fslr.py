import argparse
import nibabel as nib
from neuromaps import transforms

def transform_fsaverage_to_fslr(input_file, output_file):
    """
    Transforms surface data from fsaverage to fsLR 32k.
    Supports .mgh and .mgz inputs.
    """
    print(f"Loading input: {input_file}...")
    
    # Load the MGH file
    img = nib.load(input_file)
    data = img.get_fdata().squeeze()
    
    # Determine if it's left or right hemisphere based on filename
    # Neuromaps requires specifying the hemisphere
    if '-l_' in input_file.lower():
        hemi = 'L'
    elif '-r_' in input_file.lower():
        hemi = 'R'
    else:
        raise ValueError("Could not determine hemisphere from filename (need '-L_' or '-R_').")

    print(f"Transforming {hemi} hemisphere to fs_LR 32k...")

    # Perform the transformation
    # fsaverage is assumed to be the high-res (164k) standard
    transformed_data = transforms.fsaverage_to_fslr(
        data, 
        target_density='32k', 
        hemi=hemi, 
        method='linear'
    )

    # Save the output
    # Note: fsLR data is typically saved as GIFTI (.gii)
    print(f"Saving transformed data to: {output_file}")
    
    # If the output ends in .mgh, we convert back to MGH format
    # Otherwise, GIFTI is the standard for fsLR
    if output_file.endswith(('.mgh', '.mgz')):
        new_img = nib.MGHImage(transformed_data.astype('float32'), img.affine, img.header)
        nib.save(new_img, output_file)
    else:
        # Saving as GIFTI (recommended for fsLR 32k)
        nib.save(nib.gifti.GiftiImage(darrays=[nib.gifti.GiftiDataArray(transformed_data.astype('float32'))]), output_file)

    print("Success!")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Transform MGH data from fsaverage to fsLR 32k")
    parser.add_argument("input", help="Path to input .mgh file (e.g., lh.thickness.mgh)")
    parser.add_argument("output", help="Path to output file (e.g., lh.thickness_32k.gii)")
    
    args = parser.parse_args()
    transform_fsaverage_to_fslr(args.input, args.output)
