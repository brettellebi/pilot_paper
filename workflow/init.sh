# For snakemake

# NOTE: raw data locations:
# FTP: /nfs/ftp/private/birney-res-ftp/upload/medaka/videos/ian_pilot/all

####################
# Codon cluster
####################

ssh codon
module load singularity-3.7.0-gcc-9.3.0-dp5ffrp
bsub -Is bash
# If needing to copy videos from FTP (rule copy_videos),
# Need to use the datamover queue so that it can see the FTP drive:
# bsub -M 20000 -q datamover -Is bash
cd /hps/software/users/birney/ian/repos/pilot_paper
conda activate snakemake_6.15.5
snakemake \
  --jobs 5000 \
  --latency-wait 100 \
  --cluster-config config/cluster.yaml \
  --cluster 'bsub -g /snakemake_bgenie -J {cluster.name} -q {cluster.queue} -n {cluster.n} -M {cluster.memory} -o {cluster.outfile}' \
  --keep-going \
  --rerun-incomplete \
  --use-conda \
  --use-singularity \
  --restart-times 0 \
  -s workflow/Snakefile \
  -p

####################
# Fiji
####################

ssh codon
bsub -M 20000 -q gui -XF -Is bash
/hps/nobackup/birney/users/ian/software/Fiji.app/ImageJ-linux64 

#######################
# Build custom containers
#######################

# R
RCONT=/hps/nobackup/birney/users/ian/containers/pilot_paper/R_4.1.2.sif
singularity build --remote \
    $RCONT \
    workflow/envs/R_4.1.2/R_4.1.2.def

RCONT=/hps/nobackup/birney/users/ian/containers/pilot_paper/R_4.2.0.sif
singularity build --remote \
    $RCONT \
    workflow/envs/R_4.2.0/R_4.2.0.def

# Open CV (python)
OPENCVCONT=/hps/nobackup/birney/users/ian/containers/pilot_paper/opencv_4.5.1.sif
module load singularity-3.7.0-gcc-9.3.0-dp5ffrp
singularity build --remote \
    $OPENCVCONT \
    workflow/envs/opencv_4.5.1.def

# idtrackerai
IDCONT=/hps/nobackup/birney/users/ian/containers/MIKK_F0_tracking/idtrackerai.sif
module load singularity-3.7.0-gcc-9.3.0-dp5ffrp
singularity build --remote \
    $IDCONT \
    workflow/envs/idtrackerai.def

# hmmlearn (python)
HMMCONT=/hps/nobackup/birney/users/ian/containers/pilot_paper/hmmlearn_0.2.7.sif
module load singularity-3.7.0-gcc-9.3.0-dp5ffrp
singularity build --remote \
    $HMMCONT \
    workflow/envs/hmmlearn_0.2.7.def

# Julia
JULIACONT=/hps/nobackup/birney/users/ian/containers/pilot_paper/julia_1.7.sif
module load singularity-3.7.0-gcc-9.3.0-dp5ffrp
singularity build --remote \
    $JULIACONT \
    workflow/envs/julia_1.7.def

####################
# Run RStudio Server
####################

ssh proxy-codon
bsub -M 50000 -q short -Is bash
module load singularity-3.7.0-gcc-9.3.0-dp5ffrp
cd /hps/software/users/birney/ian/repos/pilot_paper
RCONT=/hps/nobackup/birney/users/ian/containers/pilot_paper/R_4.2.0.sif
singularity shell --bind /hps/nobackup/birney/users/ian/R_tmp/R_4.2.0/rstudio_db:/var/lib/rstudio-server \
                  --bind /hps/nobackup/birney/users/ian/R_tmp/R_4.2.0/tmp:/tmp \
                  --bind /hps/nobackup/birney/users/ian/R_tmp/R_4.2.0/run:/run \
                  $RCONT
rstudio-server kill-all
rserver \
    --rsession-config-file /hps/software/users/birney/ian/repos/pilot_paper/workflow/envs/R_4.2.0/rsession.conf \
    --server-user brettell

ssh -L 8787:hl-codon-37-04:8787 proxy-codon

####################
# Copy videos from cluster to local
####################

# To set tracking parameters
rsync -aP brettell@codon:/nfs/research/birney/users/ian/pilot/split ~/Desktop/pilot_videos

####################
# Convert to .mp4 to include in presentations
####################

# Convert entire video 

ffmpeg -i $in_vid.avi -vcodec libx264 $out_vid.mp4

# Copy segment and speed up video 

ffmpeg -i $in_vid.avi -ss 00:00:05 -t 00:01:00 -vcodec libx264 $out_vid.mp4

# NOTE: 
# -ss is start time (in sped-up time)
# -t is total vid length (in sped-up time)