# HMM states

Here we show how using a higher number of states in the HMM appeared to optimise the balance between the ability to discern differences between lines and model overfitting, yet produced asymmetries in the classified states that would impede biological interpretation.

The HMMs were trained on distance and angle variables. **Figure \@ref(fig:polar-example)** depicts how the distance and angle of travel of the movements are represented in the polar plots.

(ref:polar-example) Distance (in log~10~(pixels)) and angle of travel between a time interval of 0.2 seconds from points B → C for distance, and points A → B → C for angle. Each point represents the distance and angle at point C, and A → B is aligned vertically along the 0-180° radial axis. The figure shows only an illustrative 10,000 points, randomly selected from the full dataset. States are sorted in ascending order by mean distance.

<div class="figure">
<img src="figs/misc/dist_angle_polar_example.png" alt="(ref:polar-example)" width="100%" />
<p class="caption">(\#fig:polar-example)(ref:polar-example)</p>
</div>

## Setup

### Load libraries


```r
library(tidyverse)
library(wesanderson)
library(rstatix)
library(cowplot)
```


```r
# Variables included in HMM
VARIABLES = "dist_angle"

# Create line recode vector
line_vec = c("iCab", "HdrR", "HNI", "Kaga", "HO5")
names(line_vec) = c("icab", "hdr", "hni", "kaga", "ho5")

# Function for plot dimensions
get_wid_hei = function(N_STATES){
  if (N_STATES == 14){
    POL_ALL_WID = 12
    POL_ALL_HEI = 7
  } else {
    POL_ALL_WID = 7.5
    POL_ALL_HEI = 10
  }
  return(c(POL_ALL_WID, POL_ALL_HEI))
}

# Function for number of rows in plot
get_n_rows = function(N_STATES){ 
  if (N_STATES == 15){
    N_ROWS = 5
  } else if (N_STATES == 12 | N_STATES == 16) {
    N_ROWS = 4
  } else if (N_STATES == 17 | N_STATES == 18){
    N_ROWS = 6
  } else if (N_STATES == 14){
    N_ROWS = 2
  }
  return(N_ROWS)
}
```

## Unfavourable asymmetry with higher numbers of states

Based a visualisation of the polar plots for the each state-number/interval combination, we excluded combinations with 15 or more states due to an asymmetry across states that would create difficulties for interpreting their biological meaning. Here we show an example of the combination of 16 states and a 0.05-second interval, where states 1 and 3 are split asymmetrically (**Figure \@ref(fig:polar-asym)**). 

### 16 states; 0.05 second interval

#### Variables


```r
N_STATES = 16
INTERVAL = 0.05
IN = file.path("/hps/nobackup/birney/users/ian/pilot/hmm_out",
               INTERVAL,
               VARIABLES,
               paste(N_STATES, ".csv", sep = "")
               )

N_ROWS = get_n_rows(N_STATES)
POL_DIMS = get_wid_hei(N_STATES)
POLAR_ALL_DGE = here::here("book/figs/paper_final",
                           INTERVAL,
                           VARIABLES,
                           N_STATES,
                           "polar_all_dge.png")

```

#### Read data and process


```r
df = readr::read_csv(IN) %>% 
  # recode angle to sit between 0 and 360
  dplyr::mutate(angle_recode = ifelse(angle < 0,
                                      180 + (180 + angle),
                                      angle))
#> Rows: 14649781 Columns: 15
#> ── Column specification ────────────────────────────────────
#> Delimiter: ","
#> chr (6): assay, ref_fish, test_fish, tank_side, quadrant...
#> dbl (9): date, time, frame, seconds, x, y, distance, ang...
#> 
#> ℹ Use `spec()` to retrieve the full column specification for this data.
#> ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.

# Recode states by mean distance

rank_df = df %>% 
  dplyr::group_by(state) %>% 
  dplyr::summarise(mean_dist = mean(distance)) %>% 
  # rank
  dplyr::arrange(mean_dist) %>% 
  dplyr::mutate(rank = 1:nrow(.))

recode_vec = rank_df %>% 
  dplyr::pull(rank)
names(recode_vec) = rank_df %>% 
  dplyr::pull(state)

# Recode `state`

df = df %>% 
  dplyr::mutate(state_recode = dplyr::recode(state, !!!recode_vec))
```

#### Plot


```r
polar_all_dge = df %>% 
  # select random sample of 1e5 rows
  dplyr::slice_sample(n = 1e5) %>% 
  # factorise `state_recode`
  #dplyr::mutate(state_recode = factor(state_recode, levels = recode_vec)) %>% 
  ggplot() +
  geom_point(aes(angle_recode, log10(distance), colour = state_recode),
             alpha = 0.3, size = 0.2) +
  coord_polar() +
  facet_wrap(~state_recode, nrow = N_ROWS) +
  #theme_dark(base_size = 8) +
  cowplot::theme_cowplot(font_size = 10) +
  scale_x_continuous(labels = c(0, 90, 180, 270),
                     breaks = c(0, 90, 180, 270)) +
  scale_color_viridis_c() +
  guides(colour = "none") +
  xlab("angle of travel") +
  ylab(expression(log[10]("distance travelled in pixels")))
```


```r
# Save
ggsave(POLAR_ALL_DGE,
       polar_all_dge,
       device = "png",
       width = POL_DIMS[1],
       height = POL_DIMS[2],
       units = "in",
       dpi = 400)
```

(ref:polar-asym) Polar plots for the combination of 16 states and a 0.05-second interval. Note the asymmetry between states 1 and 3.


```r
knitr::include_graphics(POLAR_ALL_DGE)
```

<div class="figure">
<img src="figs/paper_final/0.05/dist_angle/16/polar_all_dge.png" alt="(ref:polar-asym)" width="100%" />
<p class="caption">(\#fig:polar-asym)(ref:polar-asym)</p>
</div>


## Best optimisation with state symmetry

### 14 states; 0.08 second interval

For the downstream analysis we selected the combination of 14 states with a 0.08-second interval between time points (**Figure \@ref(fig:polar-example)**), because out of the remaining combinations it appeared to optimally balance the level of overfitting and detection of differences between lines -- see Chapter \@ref(param-optim). 


```r
N_STATES = 14
INTERVAL = 0.08
IN = file.path("/hps/nobackup/birney/users/ian/pilot/hmm_out",
               INTERVAL,
               VARIABLES,
               paste(N_STATES, ".csv", sep = "")
               )

N_ROWS = get_n_rows(N_STATES)
POL_DIMS = get_wid_hei(N_STATES)
POLAR_ALL_DGE = here::here("book/figs/paper_final",
                           INTERVAL,
                           VARIABLES,
                           N_STATES,
                           "polar_all_dge.png")

```

#### Read data and process


```r
df = readr::read_csv(IN) %>% 
  # recode angle to sit between 0 and 360
  dplyr::mutate(angle_recode = ifelse(angle < 0,
                                      180 + (180 + angle),
                                      angle))
#> Rows: 9152328 Columns: 15
#> ── Column specification ────────────────────────────────────
#> Delimiter: ","
#> chr (6): assay, ref_fish, test_fish, tank_side, quadrant...
#> dbl (9): date, time, frame, seconds, x, y, distance, ang...
#> 
#> ℹ Use `spec()` to retrieve the full column specification for this data.
#> ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.

# Recode states by mean distance

rank_df = df %>% 
  dplyr::group_by(state) %>% 
  dplyr::summarise(mean_dist = mean(distance)) %>% 
  # rank
  dplyr::arrange(mean_dist) %>% 
  dplyr::mutate(rank = 1:nrow(.))

recode_vec = rank_df %>% 
  dplyr::pull(rank)
names(recode_vec) = rank_df %>% 
  dplyr::pull(state)

# Recode `state`

df = df %>% 
  dplyr::mutate(state_recode = dplyr::recode(state, !!!recode_vec))
```

#### Plot


```r
polar_all_dge = df %>% 
  # select random sample of 1e5 rows
  dplyr::slice_sample(n = 1e5) %>% 
  ggplot() +
  geom_point(aes(angle_recode, log10(distance), colour = state_recode),
             alpha = 0.3, size = 0.2) +
  coord_polar() +
  facet_wrap(~state_recode, nrow = N_ROWS) +
  cowplot::theme_cowplot(font_size = 10) +
  scale_x_continuous(labels = c(0, 90, 180, 270),
                     breaks = c(0, 90, 180, 270)) +
  scale_color_viridis_c() +
  guides(colour = "none") +
  xlab("angle of travel") +
  ylab(expression(log[10]("distance travelled in pixels")))
```


```r
# Save
ggsave(POLAR_ALL_DGE,
       polar_all_dge,
       device = "png",
       width = POL_DIMS[1],
       height = POL_DIMS[2],
       units = "in",
       dpi = 400)
```

(ref:polar-sym) Polar plots for the combination of 14 states and a 0.08-second interval. Note the symmetry across angle (e.g. left- or right-turning movements) for states 1 and 3.

<div class="figure">
<img src="figs/paper_final/0.08/dist_angle/14/polar_all_dge.png" alt="(ref:polar-sym)" width="100%" />
<p class="caption">(\#fig:polar-sym)(ref:polar-sym)</p>
</div>
