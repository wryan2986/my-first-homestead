# External design review: My First Homestead

## What the game is

My First Homestead is a calm, preschool-oriented farm game for children ages 2–5, with a parent-facing settings panel. Children visit a farm hub and help with eggs, milking, feeding, brushing, and garden care through forgiving taps, simple animations, and visual progress across days and four seasons. Optional Duck Pond and Mole Garden activities add open-ended play; there are no fail states or precision-drag chores.

**Public source repository:** https://github.com/wryan2986/my-first-homestead

**Live static build:** https://wryan2986.github.io/my-first-homestead/

## File tree (through depth 3)

The tree stops after three path components from the repository root; deeper code and documentation paths are intentionally omitted. The asset inventory below lists every content file under the asset roots, including deeper paths. Godot `.import` and `.uid` sidecars appear here when they fall within the depth limit; they are not listed as content assets. Local build output, caches, archives, Android release bundles, and agent-local files are excluded from this public review repository.

```text
.
├── .github/
│   └── workflows/
│       └── web-pages.yml
├── art/
│   ├── animals/
│   │   ├── bee_idle.png
│   │   ├── bee_idle.png.import
│   │   ├── butterfly_idle.png
│   │   ├── butterfly_idle.png.import
│   │   ├── cat_idle.png
│   │   ├── cat_idle.png.import
│   │   ├── chicken_blinking.png
│   │   ├── chicken_blinking.png.import
│   │   ├── chicken_celebrating.png
│   │   ├── chicken_celebrating.png.import
│   │   ├── chicken_eating.png
│   │   ├── chicken_eating.png.import
│   │   ├── chicken_excited.png
│   │   ├── chicken_excited.png.import
│   │   ├── chicken_happy.png
│   │   ├── chicken_happy.png.import
│   │   ├── chicken_idle.png
│   │   ├── chicken_idle.png.import
│   │   ├── chicken_states_sheet.png
│   │   ├── chicken_states_sheet.png.import
│   │   ├── chicken_walking.png
│   │   ├── chicken_walking.png.import
│   │   ├── cow_blinking.png
│   │   ├── cow_blinking.png.import
│   │   ├── cow_celebrating.png
│   │   ├── cow_celebrating.png.import
│   │   ├── cow_eating.png
│   │   ├── cow_eating.png.import
│   │   ├── cow_excited.png
│   │   ├── cow_excited.png.import
│   │   ├── cow_happy.png
│   │   ├── cow_happy.png.import
│   │   ├── cow_idle.png
│   │   ├── cow_idle.png.import
│   │   ├── cow_states_sheet.png
│   │   ├── cow_states_sheet.png.import
│   │   ├── cow_walking.png
│   │   ├── cow_walking.png.import
│   │   ├── duck_blinking.png
│   │   ├── duck_blinking.png.import
│   │   ├── duck_celebrating.png
│   │   ├── duck_celebrating.png.import
│   │   ├── duck_eating.png
│   │   ├── duck_eating.png.import
│   │   ├── duck_excited.png
│   │   ├── duck_excited.png.import
│   │   ├── duck_happy.png
│   │   ├── duck_happy.png.import
│   │   ├── duck_idle.png
│   │   ├── duck_idle.png.import
│   │   ├── duck_states_sheet.png
│   │   ├── duck_states_sheet.png.import
│   │   ├── duck_swimming_eating.png
│   │   ├── duck_swimming_eating.png.import
│   │   ├── duck_swimming_idle.png
│   │   ├── duck_swimming_idle.png.import
│   │   ├── duck_walking.png
│   │   ├── duck_walking.png.import
│   │   ├── goat_blinking.png
│   │   ├── goat_blinking.png.import
│   │   ├── goat_celebrating.png
│   │   ├── goat_celebrating.png.import
│   │   ├── goat_eating.png
│   │   ├── goat_eating.png.import
│   │   ├── goat_excited.png
│   │   ├── goat_excited.png.import
│   │   ├── goat_happy.png
│   │   ├── goat_happy.png.import
│   │   ├── goat_idle.png
│   │   ├── goat_idle.png.import
│   │   ├── goat_states_sheet.png
│   │   ├── goat_states_sheet.png.import
│   │   ├── goat_walking.png
│   │   ├── goat_walking.png.import
│   │   ├── goose_eating.png
│   │   ├── goose_eating.png.import
│   │   ├── goose_swimming_eating.png
│   │   ├── goose_swimming_eating.png.import
│   │   ├── goose_swimming_idle.png
│   │   ├── goose_swimming_idle.png.import
│   │   ├── hub_feed_chicken.png
│   │   ├── hub_feed_chicken.png.import
│   │   ├── hub_feed_goat.png
│   │   ├── hub_feed_goat.png.import
│   │   ├── hub_feed_pig.png
│   │   ├── hub_feed_pig.png.import
│   │   ├── hub_feed_sheep.png
│   │   ├── hub_feed_sheep.png.import
│   │   ├── mole_peeking.png
│   │   ├── mole_peeking.png.import
│   │   ├── mouse_idle.png
│   │   ├── mouse_idle.png.import
│   │   ├── pig_blinking.png
│   │   ├── pig_blinking.png.import
│   │   ├── pig_celebrating.png
│   │   ├── pig_celebrating.png.import
│   │   ├── pig_eating.png
│   │   ├── pig_eating.png.import
│   │   ├── pig_excited.png
│   │   ├── pig_excited.png.import
│   │   ├── pig_happy.png
│   │   ├── pig_happy.png.import
│   │   ├── pig_idle.png
│   │   ├── pig_idle.png.import
│   │   ├── pig_states_sheet.png
│   │   ├── pig_states_sheet.png.import
│   │   ├── pig_walking.png
│   │   ├── pig_walking.png.import
│   │   ├── pond_fish.png
│   │   ├── pond_fish.png.import
│   │   ├── pony_blinking.png
│   │   ├── pony_blinking.png.import
│   │   ├── pony_celebrating.png
│   │   ├── pony_celebrating.png.import
│   │   ├── pony_eating.png
│   │   ├── pony_eating.png.import
│   │   ├── pony_excited.png
│   │   ├── pony_excited.png.import
│   │   ├── pony_happy.png
│   │   ├── pony_happy.png.import
│   │   ├── pony_idle.png
│   │   ├── pony_idle.png.import
│   │   ├── pony_states_sheet.png
│   │   ├── pony_states_sheet.png.import
│   │   ├── pony_walking.png
│   │   ├── pony_walking.png.import
│   │   ├── sheep_blinking.png
│   │   ├── sheep_blinking.png.import
│   │   ├── sheep_celebrating.png
│   │   ├── sheep_celebrating.png.import
│   │   ├── sheep_eating.png
│   │   ├── sheep_eating.png.import
│   │   ├── sheep_excited.png
│   │   ├── sheep_excited.png.import
│   │   ├── sheep_happy.png
│   │   ├── sheep_happy.png.import
│   │   ├── sheep_idle.png
│   │   ├── sheep_idle.png.import
│   │   ├── sheep_states_sheet.png
│   │   ├── sheep_states_sheet.png.import
│   │   ├── sheep_walking.png
│   │   └── sheep_walking.png.import
│   ├── audio_prompts/
│   │   ├── brush_swish_prompt.txt
│   │   ├── chicken_cluck_prompt.txt
│   │   ├── completion_chime_prompt.txt
│   │   ├── feed_munch_prompt.txt
│   │   └── tap_pop_prompt.txt
│   ├── backgrounds/
│   │   ├── farmyard_layers/
│   │   ├── brushing_barn_background_fall.png
│   │   ├── brushing_barn_background_fall.png.import
│   │   ├── brushing_barn_background_spring.png
│   │   ├── brushing_barn_background_spring.png.import
│   │   ├── brushing_barn_background_summer.png
│   │   ├── brushing_barn_background_summer.png.import
│   │   ├── brushing_barn_background_winter.png
│   │   ├── brushing_barn_background_winter.png.import
│   │   ├── chicken_coop_background_fall.png
│   │   ├── chicken_coop_background_fall.png.import
│   │   ├── chicken_coop_background_spring.png
│   │   ├── chicken_coop_background_spring.png.import
│   │   ├── chicken_coop_background_summer.png
│   │   ├── chicken_coop_background_summer.png.import
│   │   ├── chicken_coop_background_winter.png
│   │   ├── chicken_coop_background_winter.png.import
│   │   ├── duck_pond_music_background_fall.png
│   │   ├── duck_pond_music_background_fall.png.import
│   │   ├── duck_pond_music_background_spring.png
│   │   ├── duck_pond_music_background_spring.png.import
│   │   ├── duck_pond_music_background_summer.png
│   │   ├── duck_pond_music_background_summer.png.import
│   │   ├── duck_pond_music_background_winter.png
│   │   ├── duck_pond_music_background_winter.png.import
│   │   ├── farmyard_background_original_backup.png
│   │   ├── farmyard_background_original_backup.png.import
│   │   ├── feeding_yard_background_fall.png
│   │   ├── feeding_yard_background_fall.png.import
│   │   ├── feeding_yard_background_spring.png
│   │   ├── feeding_yard_background_spring.png.import
│   │   ├── feeding_yard_background_summer.png
│   │   ├── feeding_yard_background_summer.png.import
│   │   ├── feeding_yard_background_winter.png
│   │   ├── feeding_yard_background_winter.png.import
│   │   ├── garden_care_background_fall.png
│   │   ├── garden_care_background_fall.png.import
│   │   ├── garden_care_background_spring.png
│   │   ├── garden_care_background_spring.png.import
│   │   ├── garden_care_background_summer.png
│   │   ├── garden_care_background_summer.png.import
│   │   ├── garden_care_background_winter.png
│   │   ├── garden_care_background_winter.png.import
│   │   ├── milking_barn_background_fall.png
│   │   ├── milking_barn_background_fall.png.import
│   │   ├── milking_barn_background_spring.png
│   │   ├── milking_barn_background_spring.png.import
│   │   ├── milking_barn_background_summer.png
│   │   ├── milking_barn_background_summer.png.import
│   │   ├── milking_barn_background_winter.png
│   │   ├── milking_barn_background_winter.png.import
│   │   ├── mole_garden_background_fall.png
│   │   ├── mole_garden_background_fall.png.import
│   │   ├── mole_garden_background_spring.png
│   │   ├── mole_garden_background_spring.png.import
│   │   ├── mole_garden_background_summer.png
│   │   ├── mole_garden_background_summer.png.import
│   │   ├── mole_garden_background_winter.png
│   │   ├── mole_garden_background_winter.png.import
│   │   ├── start_background.png
│   │   └── start_background.png.import
│   ├── effects/
│   │   ├── clean_sparkle.png
│   │   ├── clean_sparkle.png.import
│   │   ├── dirt_smudge.png
│   │   ├── dirt_smudge.png.import
│   │   ├── fall_leaf.png
│   │   ├── fall_leaf.png.import
│   │   ├── firefly_glow.png
│   │   ├── firefly_glow.png.import
│   │   ├── large_snowflake.png
│   │   ├── large_snowflake.png.import
│   │   ├── magic_sparkle.png
│   │   ├── magic_sparkle.png.import
│   │   ├── music_note_soft.png
│   │   ├── music_note_soft.png.import
│   │   ├── rainbow_tree_acorn_drop.png
│   │   ├── rainbow_tree_acorn_drop.png.import
│   │   ├── rainbow_tree_blossom_drop.png
│   │   ├── rainbow_tree_blossom_drop.png.import
│   │   ├── rainbow_tree_green_apple_drop.png
│   │   ├── rainbow_tree_green_apple_drop.png.import
│   │   ├── rainbow_tree_snow_puff_drop.png
│   │   ├── rainbow_tree_snow_puff_drop.png.import
│   │   ├── rainbow_tree_summer_fruit_drop.png
│   │   ├── rainbow_tree_summer_fruit_drop.png.import
│   │   ├── sparkle.png
│   │   ├── sparkle.png.import
│   │   ├── star.png
│   │   ├── star.png.import
│   │   ├── success_glow.png
│   │   ├── success_glow.png.import
│   │   ├── water_drop.png
│   │   └── water_drop.png.import
│   ├── fonts/
│   │   ├── NOTICE.txt
│   │   ├── NotoSans-Variable.ttf
│   │   ├── NotoSans-Variable.ttf.import
│   │   ├── NotoSansArabic-Variable.ttf
│   │   ├── NotoSansArabic-Variable.ttf.import
│   │   ├── NotoSansDevanagari-Variable.ttf
│   │   ├── NotoSansDevanagari-Variable.ttf.import
│   │   ├── NotoSansJP-Variable.ttf
│   │   ├── NotoSansJP-Variable.ttf.import
│   │   ├── NotoSansKR-Variable.ttf
│   │   ├── NotoSansKR-Variable.ttf.import
│   │   ├── NotoSansSC-Variable.ttf
│   │   └── NotoSansSC-Variable.ttf.import
│   ├── garden/
│   │   ├── harvest_items/
│   │   ├── apple.png
│   │   ├── apple.png.import
│   │   ├── carrot.png
│   │   ├── carrot.png.import
│   │   ├── corn.png
│   │   ├── corn.png.import
│   │   ├── harvest_ready.png
│   │   ├── harvest_ready.png.import
│   │   ├── harvested.png
│   │   ├── harvested.png.import
│   │   ├── lettuce.png
│   │   ├── lettuce.png.import
│   │   ├── plant_growing.png
│   │   ├── plant_growing.png.import
│   │   ├── plot_tile.png
│   │   ├── plot_tile.png.import
│   │   ├── pumpkin.png
│   │   ├── pumpkin.png.import
│   │   ├── seed.png
│   │   ├── seed.png.import
│   │   ├── sprout.png
│   │   ├── sprout.png.import
│   │   ├── strawberry.png
│   │   ├── strawberry.png.import
│   │   ├── sunflower.png
│   │   ├── sunflower.png.import
│   │   ├── tomato.png
│   │   ├── tomato.png.import
│   │   ├── turnip.png
│   │   ├── turnip.png.import
│   │   ├── wet_soil_overlay.png
│   │   └── wet_soil_overlay.png.import
│   ├── props/
│   │   ├── chicken_coop.png
│   │   ├── chicken_coop.png.import
│   │   ├── chicken_coop_fall.png
│   │   ├── chicken_coop_fall.png.import
│   │   ├── chicken_coop_hay_floor.png
│   │   ├── chicken_coop_hay_floor.png.import
│   │   ├── chicken_coop_spring.png
│   │   ├── chicken_coop_spring.png.import
│   │   ├── chicken_coop_summer.png
│   │   ├── chicken_coop_summer.png.import
│   │   ├── chicken_coop_winter.png
│   │   ├── chicken_coop_winter.png.import
│   │   ├── chicken_nest_hay_pocket.png
│   │   ├── chicken_nest_hay_pocket.png.import
│   │   ├── decoration_duck_pond.png
│   │   ├── decoration_duck_pond.png.import
│   │   ├── decoration_flower_path.png
│   │   ├── decoration_flower_path.png.import
│   │   ├── decoration_flower_path_fall.png
│   │   ├── decoration_flower_path_fall.png.import
│   │   ├── decoration_flower_path_winter.png
│   │   ├── decoration_flower_path_winter.png.import
│   │   ├── decoration_orchard_tree.png
│   │   ├── decoration_orchard_tree.png.import
│   │   ├── decoration_orchard_tree_fall.png
│   │   ├── decoration_orchard_tree_fall.png.import
│   │   ├── decoration_orchard_tree_spring.png
│   │   ├── decoration_orchard_tree_spring.png.import
│   │   ├── decoration_orchard_tree_summer.png
│   │   ├── decoration_orchard_tree_summer.png.import
│   │   ├── decoration_orchard_tree_winter.png
│   │   ├── decoration_orchard_tree_winter.png.import
│   │   ├── decoration_windmill.png
│   │   ├── decoration_windmill.png.import
│   │   ├── decoration_windmill_fall.png
│   │   ├── decoration_windmill_fall.png.import
│   │   ├── decoration_windmill_fan_0.png
│   │   ├── decoration_windmill_fan_0.png.import
│   │   ├── decoration_windmill_fan_1.png
│   │   ├── decoration_windmill_fan_1.png.import
│   │   ├── decoration_windmill_fan_2.png
│   │   ├── decoration_windmill_fan_2.png.import
│   │   ├── decoration_windmill_fan_3.png
│   │   ├── decoration_windmill_fan_3.png.import
│   │   ├── decoration_windmill_spring.png
│   │   ├── decoration_windmill_spring.png.import
│   │   ├── decoration_windmill_summer.png
│   │   ├── decoration_windmill_summer.png.import
│   │   ├── decoration_windmill_winter.png
│   │   ├── decoration_windmill_winter.png.import
│   │   ├── duck_food_crumb.png
│   │   ├── duck_food_crumb.png.import
│   │   ├── duck_pond_ripple.png
│   │   ├── duck_pond_ripple.png.import
│   │   ├── egg.png
│   │   ├── egg.png.import
│   │   ├── egg_basket.png
│   │   ├── egg_basket.png.import
│   │   ├── egg_basket_empty.png
│   │   ├── egg_basket_empty.png.import
│   │   ├── feed_bag.png
│   │   ├── feed_bag.png.import
│   │   ├── feed_cart.png
│   │   ├── feed_cart.png.import
│   │   ├── feed_pile.png
│   │   ├── feed_pile.png.import
│   │   ├── feed_pour.png
│   │   ├── feed_pour.png.import
│   │   ├── feeding_station_back.png
│   │   ├── feeding_station_back.png.import
│   │   ├── feeding_station_front.png
│   │   ├── feeding_station_front.png.import
│   │   ├── feeding_trough_contents.png
│   │   ├── feeding_trough_contents.png.import
│   │   ├── feeding_trough_fill.png
│   │   ├── feeding_trough_fill.png.import
│   │   ├── goose_food_crumb.png
│   │   ├── goose_food_crumb.png.import
│   │   ├── grooming_brush.png
│   │   ├── grooming_brush.png.import
│   │   ├── grooming_station_back.png
│   │   ├── grooming_station_back.png.import
│   │   ├── grooming_station_front.png
│   │   ├── grooming_station_front.png.import
│   │   ├── harvest_basket.png
│   │   ├── harvest_basket.png.import
│   │   ├── hay_bale.png
│   │   ├── hay_bale.png.import
│   │   ├── hub_animal_pen_front.png
│   │   ├── hub_animal_pen_front.png.import
│   │   ├── hub_feed_pen.png
│   │   ├── hub_feed_pen.png.import
│   │   ├── hub_feed_pen_fall.png
│   │   ├── hub_feed_pen_fall.png.import
│   │   ├── hub_feed_pen_spring.png
│   │   ├── hub_feed_pen_spring.png.import
│   │   ├── hub_feed_pen_summer.png
│   │   ├── hub_feed_pen_summer.png.import
│   │   ├── hub_feed_pen_winter.png
│   │   ├── hub_feed_pen_winter.png.import
│   │   ├── hub_feed_trough_front.png
│   │   ├── hub_feed_trough_front.png.import
│   │   ├── hub_garden_fenced.png
│   │   ├── hub_garden_fenced.png.import
│   │   ├── hub_garden_fenced_fall.png
│   │   ├── hub_garden_fenced_fall.png.import
│   │   ├── hub_garden_fenced_spring.png
│   │   ├── hub_garden_fenced_spring.png.import
│   │   ├── hub_garden_fenced_summer.png
│   │   ├── hub_garden_fenced_summer.png.import
│   │   ├── hub_garden_fenced_winter.png
│   │   ├── hub_garden_fenced_winter.png.import
│   │   ├── hub_grooming_stalls.png
│   │   ├── hub_grooming_stalls.png.import
│   │   ├── hub_grooming_stalls_fall.png
│   │   ├── hub_grooming_stalls_fall.png.import
│   │   ├── hub_grooming_stalls_spring.png
│   │   ├── hub_grooming_stalls_spring.png.import
│   │   ├── hub_grooming_stalls_summer.png
│   │   ├── hub_grooming_stalls_summer.png.import
│   │   ├── hub_grooming_stalls_winter.png
│   │   ├── hub_grooming_stalls_winter.png.import
│   │   ├── hub_milking_stall_cow.png
│   │   ├── hub_milking_stall_cow.png.import
│   │   ├── hub_milking_stall_cow_fall.png
│   │   ├── hub_milking_stall_cow_fall.png.import
│   │   ├── hub_milking_stall_cow_spring.png
│   │   ├── hub_milking_stall_cow_spring.png.import
│   │   ├── hub_milking_stall_cow_summer.png
│   │   ├── hub_milking_stall_cow_summer.png.import
│   │   ├── hub_milking_stall_cow_winter.png
│   │   ├── hub_milking_stall_cow_winter.png.import
│   │   ├── lily_pad_music_blue.png
│   │   ├── lily_pad_music_blue.png.import
│   │   ├── lily_pad_music_green.png
│   │   ├── lily_pad_music_green.png.import
│   │   ├── lily_pad_music_pink.png
│   │   ├── lily_pad_music_pink.png.import
│   │   ├── lily_pad_music_yellow.png
│   │   ├── lily_pad_music_yellow.png.import
│   │   ├── milk_bucket.png
│   │   ├── milk_bucket.png.import
│   │   ├── milking_stanchion_back.png
│   │   ├── milking_stanchion_back.png.import
│   │   ├── mole_burrow.png
│   │   ├── mole_burrow.png.import
│   │   ├── mole_hole.png
│   │   ├── mole_hole.png.import
│   │   ├── santa_sleigh.png
│   │   ├── santa_sleigh.png.import
│   │   ├── seed_packet.png
│   │   ├── seed_packet.png.import
│   │   ├── spring_goose_pond_ripple.png
│   │   ├── spring_goose_pond_ripple.png.import
│   │   ├── watering_can.png
│   │   └── watering_can.png.import
│   ├── ui/
│   │   ├── app_icon_192.png
│   │   ├── app_icon_192.png.import
│   │   ├── app_icon_adaptive_background_432.png
│   │   ├── app_icon_adaptive_background_432.png.import
│   │   ├── app_icon_adaptive_foreground_432.png
│   │   ├── app_icon_adaptive_foreground_432.png.import
│   │   ├── app_icon_adaptive_monochrome_432.png
│   │   ├── app_icon_adaptive_monochrome_432.png.import
│   │   ├── back_button.png
│   │   ├── back_button.png.import
│   │   ├── next_day_icon.png
│   │   ├── next_day_icon.png.import
│   │   ├── Play_button.png
│   │   ├── Play_button.png.import
│   │   ├── season_fall_leaf.png
│   │   ├── season_fall_leaf.png.import
│   │   ├── season_spring_seedling.png
│   │   ├── season_spring_seedling.png.import
│   │   ├── season_summer_sun.png
│   │   ├── season_summer_sun.png.import
│   │   ├── season_winter_snowflake.png
│   │   ├── season_winter_snowflake.png.import
│   │   ├── settings_button.png
│   │   ├── settings_button.png.import
│   │   ├── settings_parent_notebook_panel.png
│   │   ├── settings_parent_notebook_panel.png.import
│   │   ├── title_banner.png
│   │   └── title_banner.png.import
│   ├── Chicken_Coop_Fall.png
│   ├── Chicken_Coop_Fall.png.import
│   ├── Chicken_Coop_Spring.png
│   ├── Chicken_Coop_Spring.png.import
│   ├── Chicken_Coop_Summer.png
│   ├── Chicken_Coop_Summer.png.import
│   ├── Chicken_Coop_Winter.png
│   └── Chicken_Coop_Winter.png.import
├── assets/
│   └── music/
│       ├── music_chore_gentle.ogg
│       ├── music_chore_gentle.ogg.import
│       ├── music_chore_loop.ogg
│       ├── music_chore_loop.ogg.import
│       ├── music_fall_cozy_harvest.ogg
│       ├── music_fall_cozy_harvest.ogg.import
│       ├── music_farmyard_loop.ogg
│       ├── music_farmyard_loop.ogg.import
│       ├── music_farmyard_morning.ogg
│       ├── music_farmyard_morning.ogg.import
│       ├── music_farmyard_playtime.ogg
│       ├── music_farmyard_playtime.ogg.import
│       ├── music_spring_gentle_morning.ogg
│       ├── music_spring_gentle_morning.ogg.import
│       ├── music_summer_sunny_play.ogg
│       ├── music_summer_sunny_play.ogg.import
│       ├── music_sunny_farm_morning.ogg
│       ├── music_sunny_farm_morning.ogg.import
│       ├── music_sunny_farm_playtime.ogg
│       ├── music_sunny_farm_playtime.ogg.import
│       ├── music_sunny_farm_twilight.ogg
│       ├── music_sunny_farm_twilight.ogg.import
│       ├── music_winter_cozy.ogg
│       ├── music_winter_cozy.ogg.import
│       ├── music_winter_soft_bells.ogg
│       └── music_winter_soft_bells.ogg.import
├── certificates/
│   └── godot_tls_bundle.pem
├── docs/
│   ├── voice_over_recording/
│   │   ├── .gdignore
│   │   ├── voice_over_recording_script.csv
│   │   └── voice_over_recording_script.txt
│   ├── ARCHITECTURE.md
│   ├── ASSET_KEEP_LIST.txt
│   ├── ASSET_ORGANIZATION.md
│   ├── COMPETITOR_POLISH_AUDIT.md
│   ├── PC_QA_SCRIPT.md
│   ├── PLAY_ASSET_DELIVERY.md
│   ├── STABILITY_AUDIT.md
│   ├── VISUAL_QA_CHECKLIST.md
│   ├── VOICE_OVER.md
│   └── VOICE_OVER_DECISION.md
├── localization/
│   ├── translations/
│   │   ├── ar.json
│   │   ├── de.json
│   │   ├── en.json
│   │   ├── es.json
│   │   ├── fr.json
│   │   ├── hi.json
│   │   ├── it.json
│   │   ├── ja.json
│   │   ├── ko.json
│   │   ├── pt_br.json
│   │   └── zh_cn.json
│   └── voice_prompts/
│       ├── ar.json
│       ├── de.json
│       ├── en.json
│       ├── es.json
│       ├── fr.json
│       ├── hi.json
│       ├── it.json
│       ├── ja.json
│       ├── ko.json
│       ├── manual_review_manifest.json
│       ├── pt_br.json
│       └── zh_cn.json
├── resources/
│   ├── privacy_policy.txt
│   ├── privacy_policy_ar.txt
│   ├── privacy_policy_de.txt
│   ├── privacy_policy_es.txt
│   ├── privacy_policy_fr.txt
│   ├── privacy_policy_hi.txt
│   ├── privacy_policy_it.txt
│   ├── privacy_policy_ja.txt
│   ├── privacy_policy_ko.txt
│   ├── privacy_policy_pt_br.txt
│   └── privacy_policy_zh_cn.txt
├── review/
│   ├── screenshots/
│   │   ├── 01-title-screen.png
│   │   ├── 02-farm-overview-spring.png
│   │   ├── chore-brushing.png
│   │   ├── chore-eggs.png
│   │   ├── chore-feeding.png
│   │   ├── chore-milking.png
│   │   ├── chore-watering.png
│   │   ├── menu-language-picker.png
│   │   ├── menu-privacy-parents.png
│   │   ├── menu-settings-duck-timer-on.png
│   │   ├── menu-settings-gameplay.png
│   │   ├── menu-settings-language.png
│   │   ├── menu-settings-sound-scrolled.png
│   │   ├── menu-settings-sound.png
│   │   ├── optional-duck-pond.png
│   │   ├── optional-mole-garden.png
│   │   ├── progress-all-chores-complete.png
│   │   ├── season-fall.png
│   │   ├── season-summer.png
│   │   └── season-winter.png
│   └── REVIEW.md
├── scenes/
│   ├── shared/
│   │   ├── AmbientChasePair.tscn
│   │   ├── BeeCritter.tscn
│   │   ├── BouncyCritter.tscn
│   │   ├── ButterflyCritter.tscn
│   │   ├── DuckPondPlay.tscn
│   │   ├── Egg.tscn
│   │   ├── EggBasketFill.tscn
│   │   ├── FarmAnimalCard.tscn
│   │   ├── FarmNightTransition.tscn
│   │   ├── FeedingAnimalStation.tscn
│   │   ├── GardenBasketFill.tscn
│   │   ├── GardenPlot.tscn
│   │   ├── MusicManager.tscn
│   │   ├── SantaSleighFlyer.tscn
│   │   ├── SeasonalTapSurprises.tscn
│   │   └── SpringPondGeese.tscn
│   ├── AutoGameplayCapture.tscn
│   ├── BrushingScene.tscn
│   ├── DuckPondMusicScene.tscn
│   ├── EggCollectingScene.tscn
│   ├── FarmyardScene.tscn
│   ├── FeedingScene.tscn
│   ├── MilkingScene.tscn
│   ├── MoleGardenScene.tscn
│   ├── settings_panel.tscn
│   ├── StartScene.tscn
│   └── WateringScene.tscn
├── scripts/
│   ├── chores/
│   │   ├── BrushingScene.gd
│   │   ├── BrushingScene.gd.uid
│   │   ├── FeedingScene.gd
│   │   ├── FeedingScene.gd.uid
│   │   ├── GardenScene.gd
│   │   ├── GardenScene.gd.uid
│   │   ├── MilkingScene.gd
│   │   └── MilkingScene.gd.uid
│   ├── core/
│   │   ├── ChoreAssist.gd
│   │   ├── ChoreAssist.gd.uid
│   │   ├── ChoreCompletionFlow.gd
│   │   ├── ChoreCompletionFlow.gd.uid
│   │   ├── ChoreRuntime.gd
│   │   ├── ChoreRuntime.gd.uid
│   │   ├── FarmFeedback.gd
│   │   ├── FarmFeedback.gd.uid
│   │   ├── FarmState.gd
│   │   ├── FarmState.gd.uid
│   │   ├── GameSettings.gd
│   │   ├── GameSettings.gd.uid
│   │   ├── LocalizationFonts.gd
│   │   ├── LocalizationFonts.gd.uid
│   │   ├── MusicManager.gd
│   │   ├── MusicManager.gd.uid
│   │   ├── SceneEntranceMotion.gd
│   │   ├── SceneEntranceMotion.gd.uid
│   │   ├── SceneHotspot.gd
│   │   ├── SceneHotspot.gd.uid
│   │   ├── SceneNavigator.gd
│   │   ├── SceneNavigator.gd.uid
│   │   ├── VoiceOverManager.gd
│   │   └── VoiceOverManager.gd.uid
│   ├── optional/
│   │   ├── DuckPondMusicScene.gd
│   │   ├── DuckPondMusicScene.gd.uid
│   │   ├── MoleGardenScene.gd
│   │   └── MoleGardenScene.gd.uid
│   ├── ui/
│   │   ├── AmbientChasePair.gd
│   │   ├── AmbientChasePair.gd.uid
│   │   ├── BeeCritter.gd
│   │   ├── BeeCritter.gd.uid
│   │   ├── BouncyCritter.gd
│   │   ├── BouncyCritter.gd.uid
│   │   ├── ButtonTouchProxy.gd
│   │   ├── ButtonTouchProxy.gd.uid
│   │   ├── DuckPondPlay.gd
│   │   ├── DuckPondPlay.gd.uid
│   │   ├── EggBasketFill.gd
│   │   ├── EggBasketFill.gd.uid
│   │   ├── FarmAnimalCard.gd
│   │   ├── FarmAnimalCard.gd.uid
│   │   ├── FarmNightTransition.gd
│   │   ├── FarmNightTransition.gd.uid
│   │   ├── FeedingAnimalStation.gd
│   │   ├── FeedingAnimalStation.gd.uid
│   │   ├── GardenBasketFill.gd
│   │   ├── GardenBasketFill.gd.uid
│   │   ├── GardenPlot.gd
│   │   ├── GardenPlot.gd.uid
│   │   ├── HubAnimalWanderer.gd
│   │   ├── HubAnimalWanderer.gd.uid
│   │   ├── MilkBucketFill.gd
│   │   ├── MilkBucketFill.gd.uid
│   │   ├── ResponsiveCoverNode2D.gd
│   │   ├── ResponsiveCoverNode2D.gd.uid
│   │   ├── ResponsiveCoverSprite2D.gd
│   │   ├── ResponsiveCoverSprite2D.gd.uid
│   │   ├── ResponsiveCoverTextureRect.gd
│   │   ├── ResponsiveCoverTextureRect.gd.uid
│   │   ├── ResponsiveSceneLayout.gd
│   │   ├── ResponsiveSceneLayout.gd.uid
│   │   ├── SantaSleighFlyer.gd
│   │   ├── SantaSleighFlyer.gd.uid
│   │   ├── SeasonalBackground.gd
│   │   ├── SeasonalBackground.gd.uid
│   │   ├── SeasonalTapSurprises.gd
│   │   ├── SeasonalTapSurprises.gd.uid
│   │   ├── SettingsPanel.gd
│   │   ├── SettingsPanel.gd.uid
│   │   ├── SettingsToggleTouchProxy.gd
│   │   ├── SettingsToggleTouchProxy.gd.uid
│   │   ├── SliderTouchProxy.gd
│   │   ├── SliderTouchProxy.gd.uid
│   │   ├── SpringPondGeese.gd
│   │   ├── SpringPondGeese.gd.uid
│   │   ├── ToggleSwitchVisual.gd
│   │   └── ToggleSwitchVisual.gd.uid
│   ├── AnimalPenArea.gd
│   ├── AnimalPenArea.gd.uid
│   ├── AutoGameplayCapture.gd
│   ├── AutoGameplayCapture.gd.uid
│   ├── ChickenCoopArea.gd
│   ├── ChickenCoopArea.gd.uid
│   ├── CowArea.gd
│   ├── CowArea.gd.uid
│   ├── Egg.gd
│   ├── Egg.gd.uid
│   ├── EggCollectingScene.gd
│   ├── EggCollectingScene.gd.uid
│   ├── FarmyardScene.gd
│   ├── FarmyardScene.gd.uid
│   ├── FeedArea.gd
│   ├── FeedArea.gd.uid
│   ├── GardenArea.gd
│   ├── GardenArea.gd.uid
│   ├── RainbowTreeDecoration.gd
│   ├── RainbowTreeDecoration.gd.uid
│   ├── StartScene.gd
│   ├── StartScene.gd.uid
│   ├── WindmillDecoration.gd
│   └── WindmillDecoration.gd.uid
├── sounds/
│   ├── voice_over/
│   │   ├── locales/
│   │   ├── brushing_complete_0.ogg
│   │   ├── brushing_complete_0.ogg.import
│   │   ├── brushing_complete_1.ogg
│   │   ├── brushing_complete_1.ogg.import
│   │   ├── brushing_complete_2.ogg
│   │   ├── brushing_complete_2.ogg.import
│   │   ├── brushing_complete_3.ogg
│   │   ├── brushing_complete_3.ogg.import
│   │   ├── brushing_complete_4.ogg
│   │   ├── brushing_complete_4.ogg.import
│   │   ├── brushing_hint_gentle.ogg
│   │   ├── brushing_hint_gentle.ogg.import
│   │   ├── brushing_hint_strong.ogg
│   │   ├── brushing_hint_strong.ogg.import
│   │   ├── brushing_hint_tool_gentle.ogg
│   │   ├── brushing_hint_tool_gentle.ogg.import
│   │   ├── brushing_hint_tool_strong.ogg
│   │   ├── brushing_hint_tool_strong.ogg.import
│   │   ├── eggs_complete_0.ogg
│   │   ├── eggs_complete_0.ogg.import
│   │   ├── eggs_complete_1.ogg
│   │   ├── eggs_complete_1.ogg.import
│   │   ├── eggs_complete_2.ogg
│   │   ├── eggs_complete_2.ogg.import
│   │   ├── eggs_complete_3.ogg
│   │   ├── eggs_complete_3.ogg.import
│   │   ├── eggs_complete_4.ogg
│   │   ├── eggs_complete_4.ogg.import
│   │   ├── eggs_hint_basket_gentle.ogg
│   │   ├── eggs_hint_basket_gentle.ogg.import
│   │   ├── eggs_hint_basket_strong.ogg
│   │   ├── eggs_hint_basket_strong.ogg.import
│   │   ├── eggs_hint_gentle.ogg
│   │   ├── eggs_hint_gentle.ogg.import
│   │   ├── eggs_hint_strong.ogg
│   │   ├── eggs_hint_strong.ogg.import
│   │   ├── feeding_complete_0.ogg
│   │   ├── feeding_complete_0.ogg.import
│   │   ├── feeding_complete_1.ogg
│   │   ├── feeding_complete_1.ogg.import
│   │   ├── feeding_complete_2.ogg
│   │   ├── feeding_complete_2.ogg.import
│   │   ├── feeding_complete_3.ogg
│   │   ├── feeding_complete_3.ogg.import
│   │   ├── feeding_complete_4.ogg
│   │   ├── feeding_complete_4.ogg.import
│   │   ├── feeding_hint_gentle.ogg
│   │   ├── feeding_hint_gentle.ogg.import
│   │   ├── feeding_hint_strong.ogg
│   │   ├── feeding_hint_strong.ogg.import
│   │   ├── garden_complete_0.ogg
│   │   ├── garden_complete_0.ogg.import
│   │   ├── garden_complete_1.ogg
│   │   ├── garden_complete_1.ogg.import
│   │   ├── garden_complete_2.ogg
│   │   ├── garden_complete_2.ogg.import
│   │   ├── garden_complete_3.ogg
│   │   ├── garden_complete_3.ogg.import
│   │   ├── garden_complete_4.ogg
│   │   ├── garden_complete_4.ogg.import
│   │   ├── garden_hint_plot_gentle.ogg
│   │   ├── garden_hint_plot_gentle.ogg.import
│   │   ├── garden_hint_plot_strong.ogg
│   │   ├── garden_hint_plot_strong.ogg.import
│   │   ├── garden_hint_winter_gentle.ogg
│   │   ├── garden_hint_winter_gentle.ogg.import
│   │   ├── garden_hint_winter_strong.ogg
│   │   ├── garden_hint_winter_strong.ogg.import
│   │   ├── milking_complete_0.ogg
│   │   ├── milking_complete_0.ogg.import
│   │   ├── milking_complete_1.ogg
│   │   ├── milking_complete_1.ogg.import
│   │   ├── milking_complete_2.ogg
│   │   ├── milking_complete_2.ogg.import
│   │   ├── milking_complete_3.ogg
│   │   ├── milking_complete_3.ogg.import
│   │   ├── milking_complete_4.ogg
│   │   ├── milking_complete_4.ogg.import
│   │   ├── milking_hint_cow_gentle.ogg
│   │   ├── milking_hint_cow_gentle.ogg.import
│   │   ├── milking_hint_cow_strong.ogg
│   │   ├── milking_hint_cow_strong.ogg.import
│   │   ├── milking_hint_gentle.ogg
│   │   ├── milking_hint_gentle.ogg.import
│   │   ├── milking_hint_strong.ogg
│   │   ├── milking_hint_strong.ogg.import
│   │   ├── milking_pet_hint_gentle.ogg
│   │   ├── milking_pet_hint_gentle.ogg.import
│   │   ├── milking_pet_hint_strong.ogg
│   │   ├── milking_pet_hint_strong.ogg.import
│   │   └── voice_lines.json
│   ├── bee_buzz.wav
│   ├── bee_buzz.wav.import
│   ├── brush.ogg
│   ├── brush.ogg.import
│   ├── chicken_cluck_variant_1.ogg
│   ├── chicken_cluck_variant_1.ogg.import
│   ├── chicken_cluck_variant_2.ogg
│   ├── chicken_cluck_variant_2.ogg.import
│   ├── chicken_cluck_variant_3.ogg
│   ├── chicken_cluck_variant_3.ogg.import
│   ├── chicken_cluck_variant_4.ogg
│   ├── chicken_cluck_variant_4.ogg.import
│   ├── chicken_cluck_variant_5.ogg
│   ├── chicken_cluck_variant_5.ogg.import
│   ├── complete.ogg
│   ├── complete.ogg.import
│   ├── cow_moo.wav
│   ├── cow_moo.wav.import
│   ├── duck_pond_note_a.wav
│   ├── duck_pond_note_a.wav.import
│   ├── duck_pond_note_c.wav
│   ├── duck_pond_note_c.wav.import
│   ├── duck_pond_note_e.wav
│   ├── duck_pond_note_e.wav.import
│   ├── duck_pond_note_g.wav
│   ├── duck_pond_note_g.wav.import
│   ├── duck_quack.wav
│   ├── duck_quack.wav.import
│   ├── eggcollect.wav
│   ├── eggcollect.wav.import
│   ├── feed.wav
│   ├── feed.wav.import
│   ├── harvest.wav
│   ├── harvest.wav.import
│   ├── milk.ogg
│   ├── milk.ogg.import
│   ├── next_day.wav
│   ├── next_day.wav.import
│   ├── night_crickets_clip_1.ogg
│   ├── night_crickets_clip_1.ogg.import
│   ├── night_crickets_clip_2.ogg
│   ├── night_crickets_clip_2.ogg.import
│   ├── night_crickets_clip_3.ogg
│   ├── night_crickets_clip_3.ogg.import
│   ├── owl_hoot_variant_1.ogg
│   ├── owl_hoot_variant_1.ogg.import
│   ├── owl_hoot_variant_2.ogg
│   ├── owl_hoot_variant_2.ogg.import
│   ├── owl_hoot_variant_3.ogg
│   ├── owl_hoot_variant_3.ogg.import
│   ├── santa_bells.wav
│   ├── santa_bells.wav.import
│   ├── santa_ho_ho_variant_1.ogg
│   ├── santa_ho_ho_variant_1.ogg.import
│   ├── santa_ho_ho_variant_2.ogg
│   ├── santa_ho_ho_variant_2.ogg.import
│   ├── santa_ho_ho_variant_3.ogg
│   ├── santa_ho_ho_variant_3.ogg.import
│   ├── tap.wav
│   ├── tap.wav.import
│   ├── water.ogg
│   └── water.ogg.import
├── tools/
│   ├── voice_comparison/
│   │   ├── providers/
│   │   ├── .env.example
│   │   ├── .gdignore
│   │   ├── compare_voices.py
│   │   ├── comparison_manifest.json
│   │   ├── README.md
│   │   └── requirements.txt
│   ├── voice_generation/
│   │   ├── santa/
│   │   ├── .gdignore
│   │   ├── generate_voice.py
│   │   ├── narration_manifest.json
│   │   ├── README.md
│   │   └── requirements.txt
│   ├── android_size_report.py
│   ├── android_store_screenshots.gd
│   ├── android_store_screenshots.gd.uid
│   ├── annotate_android_store_screenshots.py
│   ├── aspect_ratio_capture.gd
│   ├── aspect_ratio_capture.gd.uid
│   ├── audio_loudness_audit.py
│   ├── audit_assets.py
│   ├── bump_android_release.py
│   ├── duck_pond_asset_wiring_test.gd
│   ├── duck_pond_asset_wiring_test.gd.uid
│   ├── egg_basket_fill_test.gd
│   ├── egg_basket_fill_test.gd.uid
│   ├── export_voice_over_recording_script.py
│   ├── feeding_station_visual_test.gd
│   ├── feeding_station_visual_test.gd.uid
│   ├── garden_plot_visual_test.gd
│   ├── garden_plot_visual_test.gd.uid
│   ├── generate_placeholder_music.py
│   ├── generate_polished_assets.py
│   ├── generate_voice_over.py
│   ├── godot_project_smoke.gd
│   ├── godot_project_smoke.gd.uid
│   ├── google_generate_locale_packs.py
│   ├── goose_pond_mole_holes_test.gd
│   ├── goose_pond_mole_holes_test.gd.uid
│   ├── local_kokoro_generate_locale_packs.py
│   ├── milking_scene_cache_test.gd
│   ├── milking_scene_cache_test.gd.uid
│   ├── print_play_asset_delivery_packs.py
│   ├── project_health_check.py
│   ├── qa_asset_preview.py
│   ├── rainbow_tree_drop_mapping_test.gd
│   ├── rainbow_tree_drop_mapping_test.gd.uid
│   ├── release_readiness_check.py
│   ├── repair_mislabeled_voice_ogg.py
│   ├── santa_audio_single_clip_test.gd
│   ├── santa_audio_single_clip_test.gd.uid
│   ├── scene_navigator_persistent_pool_test.gd
│   ├── scene_navigator_persistent_pool_test.gd.uid
│   ├── settings_language_popup_layout_test.gd
│   ├── settings_language_popup_layout_test.gd.uid
│   ├── settings_mute_button_click_test.gd
│   ├── settings_mute_button_click_test.gd.uid
│   ├── settings_privacy_policy_test.gd
│   ├── settings_privacy_policy_test.gd.uid
│   ├── settings_timer_stepper_test.gd
│   ├── settings_timer_stepper_test.gd.uid
│   ├── verify_android_release.ps1
│   ├── verify_localization.py
│   ├── verify_voice_over.py
│   ├── verify_voice_prompt_translations.py
│   ├── windmill_spin_animation_test.gd
│   └── windmill_spin_animation_test.gd.uid
├── .gitattributes
├── .gitignore
├── export_presets.cfg
├── icon.svg
├── icon.svg.import
├── project.godot
└── README.md
```

## Asset inventory and origin

Inventory scope: authored/runtime content under `art/`, `assets/`, `sounds/`, `localization/`, and `resources/`, plus the root `icon.svg` (868 files). Godot `.import`/`.uid` sidecars are metadata and are not counted as content assets. **No asset is documented as literally hand-drawn.** The labels below distinguish script-generated, documented AI-generated, and uncertain origins; they are not a substitute for missing per-file source records. For PNGs whose relative paths are written by `tools/generate_polished_assets.py`, the stored pixels differ from a fresh run of that script, so the script-path label is evidence of a procedural source path, not proof of the exact current bitmap provenance. The project comments explicitly identify the duck sprite family as image-generated; remaining imported raster illustrations are marked AI-generated by inference from the project documentation, because the repository does not preserve prompts or per-file attribution.

### AI-generated illustration (inferred; per-file source record absent) (142)

- `art/animals/bee_idle.png`
- `art/animals/butterfly_idle.png`
- `art/animals/cat_idle.png`
- `art/animals/duck_blinking.png`
- `art/animals/duck_celebrating.png`
- `art/animals/duck_eating.png`
- `art/animals/duck_excited.png`
- `art/animals/duck_happy.png`
- `art/animals/duck_idle.png`
- `art/animals/duck_states_sheet.png`
- `art/animals/duck_swimming_eating.png`
- `art/animals/duck_swimming_idle.png`
- `art/animals/duck_walking.png`
- `art/animals/goose_eating.png`
- `art/animals/goose_swimming_eating.png`
- `art/animals/goose_swimming_idle.png`
- `art/animals/mole_peeking.png`
- `art/animals/mouse_idle.png`
- `art/animals/pond_fish.png`
- `art/backgrounds/brushing_barn_background_fall.png`
- `art/backgrounds/brushing_barn_background_spring.png`
- `art/backgrounds/brushing_barn_background_summer.png`
- `art/backgrounds/brushing_barn_background_winter.png`
- `art/backgrounds/chicken_coop_background_fall.png`
- `art/backgrounds/chicken_coop_background_spring.png`
- `art/backgrounds/chicken_coop_background_summer.png`
- `art/backgrounds/chicken_coop_background_winter.png`
- `art/backgrounds/duck_pond_music_background_fall.png`
- `art/backgrounds/duck_pond_music_background_spring.png`
- `art/backgrounds/duck_pond_music_background_summer.png`
- `art/backgrounds/duck_pond_music_background_winter.png`
- `art/backgrounds/farmyard_background_original_backup.png`
- `art/backgrounds/farmyard_layers/farmyard_base_fall.png`
- `art/backgrounds/farmyard_layers/farmyard_base_fall_bleed.png`
- `art/backgrounds/farmyard_layers/farmyard_base_spring.png`
- `art/backgrounds/farmyard_layers/farmyard_base_spring_bleed.png`
- `art/backgrounds/farmyard_layers/farmyard_base_summer.png`
- `art/backgrounds/farmyard_layers/farmyard_base_summer_bleed.png`
- `art/backgrounds/farmyard_layers/farmyard_base_winter.png`
- `art/backgrounds/farmyard_layers/farmyard_base_winter_bleed.png`
- `art/backgrounds/farmyard_layers/ground_base_bleed.png`
- `art/backgrounds/farmyard_layers/season_fall_overlay.png`
- `art/backgrounds/farmyard_layers/season_fall_overlay_bleed.png`
- `art/backgrounds/farmyard_layers/season_spring_overlay.png`
- `art/backgrounds/farmyard_layers/season_spring_overlay_bleed.png`
- `art/backgrounds/farmyard_layers/season_summer_overlay.png`
- `art/backgrounds/farmyard_layers/season_summer_overlay_bleed.png`
- `art/backgrounds/farmyard_layers/season_winter_overlay.png`
- `art/backgrounds/farmyard_layers/season_winter_overlay_bleed.png`
- `art/backgrounds/farmyard_layers/sky_bleed.png`
- `art/backgrounds/feeding_yard_background_fall.png`
- `art/backgrounds/feeding_yard_background_spring.png`
- `art/backgrounds/feeding_yard_background_summer.png`
- `art/backgrounds/feeding_yard_background_winter.png`
- `art/backgrounds/garden_care_background_fall.png`
- `art/backgrounds/garden_care_background_spring.png`
- `art/backgrounds/garden_care_background_summer.png`
- `art/backgrounds/garden_care_background_winter.png`
- `art/backgrounds/milking_barn_background_fall.png`
- `art/backgrounds/milking_barn_background_spring.png`
- `art/backgrounds/milking_barn_background_summer.png`
- `art/backgrounds/milking_barn_background_winter.png`
- `art/backgrounds/mole_garden_background_fall.png`
- `art/backgrounds/mole_garden_background_spring.png`
- `art/backgrounds/mole_garden_background_summer.png`
- `art/backgrounds/mole_garden_background_winter.png`
- `art/Chicken_Coop_Fall.png`
- `art/Chicken_Coop_Spring.png`
- `art/Chicken_Coop_Summer.png`
- `art/Chicken_Coop_Winter.png`
- `art/effects/fall_leaf.png`
- `art/effects/firefly_glow.png`
- `art/effects/large_snowflake.png`
- `art/effects/magic_sparkle.png`
- `art/effects/music_note_soft.png`
- `art/effects/rainbow_tree_acorn_drop.png`
- `art/effects/rainbow_tree_blossom_drop.png`
- `art/effects/rainbow_tree_green_apple_drop.png`
- `art/effects/rainbow_tree_snow_puff_drop.png`
- `art/effects/rainbow_tree_summer_fruit_drop.png`
- `art/garden/harvest_items/apple_item.png`
- `art/garden/harvest_items/carrot_item.png`
- `art/garden/harvest_items/corn_item.png`
- `art/garden/harvest_items/lettuce_item.png`
- `art/garden/harvest_items/pumpkin_item.png`
- `art/garden/harvest_items/strawberry_item.png`
- `art/garden/harvest_items/sunflower_item.png`
- `art/garden/harvest_items/tomato_item.png`
- `art/garden/harvest_items/turnip_item.png`
- `art/garden/lettuce.png`
- `art/props/chicken_coop_fall.png`
- `art/props/chicken_coop_hay_floor.png`
- `art/props/chicken_coop_spring.png`
- `art/props/chicken_coop_summer.png`
- `art/props/chicken_coop_winter.png`
- `art/props/decoration_flower_path_fall.png`
- `art/props/decoration_flower_path_winter.png`
- `art/props/decoration_orchard_tree_fall.png`
- `art/props/decoration_orchard_tree_spring.png`
- `art/props/decoration_orchard_tree_summer.png`
- `art/props/decoration_orchard_tree_winter.png`
- `art/props/decoration_windmill_fan_0.png`
- `art/props/decoration_windmill_fan_1.png`
- `art/props/decoration_windmill_fan_2.png`
- `art/props/decoration_windmill_fan_3.png`
- `art/props/duck_food_crumb.png`
- `art/props/duck_pond_ripple.png`
- `art/props/egg_basket_empty.png`
- `art/props/feeding_trough_contents.png`
- `art/props/feeding_trough_fill.png`
- `art/props/goose_food_crumb.png`
- `art/props/harvest_basket.png`
- `art/props/hub_feed_pen_fall.png`
- `art/props/hub_feed_pen_spring.png`
- `art/props/hub_feed_pen_summer.png`
- `art/props/hub_feed_pen_winter.png`
- `art/props/hub_garden_fenced.png`
- `art/props/hub_garden_fenced_fall.png`
- `art/props/hub_garden_fenced_spring.png`
- `art/props/hub_garden_fenced_summer.png`
- `art/props/hub_garden_fenced_winter.png`
- `art/props/hub_grooming_stalls_fall.png`
- `art/props/hub_grooming_stalls_spring.png`
- `art/props/hub_grooming_stalls_summer.png`
- `art/props/hub_grooming_stalls_winter.png`
- `art/props/hub_milking_stall_cow.png`
- `art/props/hub_milking_stall_cow_fall.png`
- `art/props/hub_milking_stall_cow_spring.png`
- `art/props/hub_milking_stall_cow_summer.png`
- `art/props/hub_milking_stall_cow_winter.png`
- `art/props/lily_pad_music_blue.png`
- `art/props/lily_pad_music_green.png`
- `art/props/lily_pad_music_pink.png`
- `art/props/lily_pad_music_yellow.png`
- `art/props/milking_stanchion_back.png`
- `art/props/mole_burrow.png`
- `art/props/mole_hole.png`
- `art/props/santa_sleigh.png`
- `art/props/seed_packet.png`
- `art/props/spring_goose_pond_ripple.png`
- `art/ui/Play_button.png`
- `art/ui/settings_parent_notebook_panel.png`

### AI-generated music (Stable Audio 3 small; per project documentation) (13)

- `assets/music/music_chore_gentle.ogg`
- `assets/music/music_chore_loop.ogg`
- `assets/music/music_fall_cozy_harvest.ogg`
- `assets/music/music_farmyard_loop.ogg`
- `assets/music/music_farmyard_morning.ogg`
- `assets/music/music_farmyard_playtime.ogg`
- `assets/music/music_spring_gentle_morning.ogg`
- `assets/music/music_summer_sunny_play.ogg`
- `assets/music/music_sunny_farm_morning.ogg`
- `assets/music/music_sunny_farm_playtime.ogg`
- `assets/music/music_sunny_farm_twilight.ogg`
- `assets/music/music_winter_cozy.ogg`
- `assets/music/music_winter_soft_bells.ogg`

### AI-generated voice audio (Google Cloud Chirp 3 HD; per project documentation) (501)

- `sounds/voice_over/brushing_complete_0.ogg`
- `sounds/voice_over/brushing_complete_1.ogg`
- `sounds/voice_over/brushing_complete_2.ogg`
- `sounds/voice_over/brushing_complete_3.ogg`
- `sounds/voice_over/brushing_complete_4.ogg`
- `sounds/voice_over/brushing_hint_gentle.ogg`
- `sounds/voice_over/brushing_hint_strong.ogg`
- `sounds/voice_over/brushing_hint_tool_gentle.ogg`
- `sounds/voice_over/brushing_hint_tool_strong.ogg`
- `sounds/voice_over/eggs_complete_0.ogg`
- `sounds/voice_over/eggs_complete_1.ogg`
- `sounds/voice_over/eggs_complete_2.ogg`
- `sounds/voice_over/eggs_complete_3.ogg`
- `sounds/voice_over/eggs_complete_4.ogg`
- `sounds/voice_over/eggs_hint_basket_gentle.ogg`
- `sounds/voice_over/eggs_hint_basket_strong.ogg`
- `sounds/voice_over/eggs_hint_gentle.ogg`
- `sounds/voice_over/eggs_hint_strong.ogg`
- `sounds/voice_over/feeding_complete_0.ogg`
- `sounds/voice_over/feeding_complete_1.ogg`
- `sounds/voice_over/feeding_complete_2.ogg`
- `sounds/voice_over/feeding_complete_3.ogg`
- `sounds/voice_over/feeding_complete_4.ogg`
- `sounds/voice_over/feeding_hint_gentle.ogg`
- `sounds/voice_over/feeding_hint_strong.ogg`
- `sounds/voice_over/garden_complete_0.ogg`
- `sounds/voice_over/garden_complete_1.ogg`
- `sounds/voice_over/garden_complete_2.ogg`
- `sounds/voice_over/garden_complete_3.ogg`
- `sounds/voice_over/garden_complete_4.ogg`
- `sounds/voice_over/garden_hint_plot_gentle.ogg`
- `sounds/voice_over/garden_hint_plot_strong.ogg`
- `sounds/voice_over/garden_hint_winter_gentle.ogg`
- `sounds/voice_over/garden_hint_winter_strong.ogg`
- `sounds/voice_over/locales/ar/brushing_complete_0.ogg`
- `sounds/voice_over/locales/ar/brushing_complete_1.ogg`
- `sounds/voice_over/locales/ar/brushing_complete_2.ogg`
- `sounds/voice_over/locales/ar/brushing_complete_3.ogg`
- `sounds/voice_over/locales/ar/brushing_complete_4.ogg`
- `sounds/voice_over/locales/ar/brushing_hint_gentle.ogg`
- `sounds/voice_over/locales/ar/brushing_hint_strong.ogg`
- `sounds/voice_over/locales/ar/brushing_hint_tool_gentle.ogg`
- `sounds/voice_over/locales/ar/brushing_hint_tool_strong.ogg`
- `sounds/voice_over/locales/ar/eggs_complete_0.ogg`
- `sounds/voice_over/locales/ar/eggs_complete_1.ogg`
- `sounds/voice_over/locales/ar/eggs_complete_2.ogg`
- `sounds/voice_over/locales/ar/eggs_complete_3.ogg`
- `sounds/voice_over/locales/ar/eggs_complete_4.ogg`
- `sounds/voice_over/locales/ar/eggs_hint_basket_gentle.ogg`
- `sounds/voice_over/locales/ar/eggs_hint_basket_strong.ogg`
- `sounds/voice_over/locales/ar/eggs_hint_gentle.ogg`
- `sounds/voice_over/locales/ar/eggs_hint_strong.ogg`
- `sounds/voice_over/locales/ar/feeding_complete_0.ogg`
- `sounds/voice_over/locales/ar/feeding_complete_1.ogg`
- `sounds/voice_over/locales/ar/feeding_complete_2.ogg`
- `sounds/voice_over/locales/ar/feeding_complete_3.ogg`
- `sounds/voice_over/locales/ar/feeding_complete_4.ogg`
- `sounds/voice_over/locales/ar/feeding_hint_gentle.ogg`
- `sounds/voice_over/locales/ar/feeding_hint_strong.ogg`
- `sounds/voice_over/locales/ar/garden_complete_0.ogg`
- `sounds/voice_over/locales/ar/garden_complete_1.ogg`
- `sounds/voice_over/locales/ar/garden_complete_2.ogg`
- `sounds/voice_over/locales/ar/garden_complete_3.ogg`
- `sounds/voice_over/locales/ar/garden_complete_4.ogg`
- `sounds/voice_over/locales/ar/garden_hint_plot_gentle.ogg`
- `sounds/voice_over/locales/ar/garden_hint_plot_strong.ogg`
- `sounds/voice_over/locales/ar/garden_hint_winter_gentle.ogg`
- `sounds/voice_over/locales/ar/garden_hint_winter_strong.ogg`
- `sounds/voice_over/locales/ar/milking_complete_0.ogg`
- `sounds/voice_over/locales/ar/milking_complete_1.ogg`
- `sounds/voice_over/locales/ar/milking_complete_2.ogg`
- `sounds/voice_over/locales/ar/milking_complete_3.ogg`
- `sounds/voice_over/locales/ar/milking_complete_4.ogg`
- `sounds/voice_over/locales/ar/milking_hint_cow_gentle.ogg`
- `sounds/voice_over/locales/ar/milking_hint_cow_strong.ogg`
- `sounds/voice_over/locales/ar/milking_hint_gentle.ogg`
- `sounds/voice_over/locales/ar/milking_hint_strong.ogg`
- `sounds/voice_over/locales/ar/milking_pet_hint_gentle.ogg`
- `sounds/voice_over/locales/ar/milking_pet_hint_strong.ogg`
- `sounds/voice_over/locales/de-DE/santa_full_greeting.ogg`
- `sounds/voice_over/locales/de/brushing_complete_0.ogg`
- `sounds/voice_over/locales/de/brushing_complete_1.ogg`
- `sounds/voice_over/locales/de/brushing_complete_2.ogg`
- `sounds/voice_over/locales/de/brushing_complete_3.ogg`
- `sounds/voice_over/locales/de/brushing_complete_4.ogg`
- `sounds/voice_over/locales/de/brushing_hint_gentle.ogg`
- `sounds/voice_over/locales/de/brushing_hint_strong.ogg`
- `sounds/voice_over/locales/de/brushing_hint_tool_gentle.ogg`
- `sounds/voice_over/locales/de/brushing_hint_tool_strong.ogg`
- `sounds/voice_over/locales/de/eggs_complete_0.ogg`
- `sounds/voice_over/locales/de/eggs_complete_1.ogg`
- `sounds/voice_over/locales/de/eggs_complete_2.ogg`
- `sounds/voice_over/locales/de/eggs_complete_3.ogg`
- `sounds/voice_over/locales/de/eggs_complete_4.ogg`
- `sounds/voice_over/locales/de/eggs_hint_basket_gentle.ogg`
- `sounds/voice_over/locales/de/eggs_hint_basket_strong.ogg`
- `sounds/voice_over/locales/de/eggs_hint_gentle.ogg`
- `sounds/voice_over/locales/de/eggs_hint_strong.ogg`
- `sounds/voice_over/locales/de/feeding_complete_0.ogg`
- `sounds/voice_over/locales/de/feeding_complete_1.ogg`
- `sounds/voice_over/locales/de/feeding_complete_2.ogg`
- `sounds/voice_over/locales/de/feeding_complete_3.ogg`
- `sounds/voice_over/locales/de/feeding_complete_4.ogg`
- `sounds/voice_over/locales/de/feeding_hint_gentle.ogg`
- `sounds/voice_over/locales/de/feeding_hint_strong.ogg`
- `sounds/voice_over/locales/de/garden_complete_0.ogg`
- `sounds/voice_over/locales/de/garden_complete_1.ogg`
- `sounds/voice_over/locales/de/garden_complete_2.ogg`
- `sounds/voice_over/locales/de/garden_complete_3.ogg`
- `sounds/voice_over/locales/de/garden_complete_4.ogg`
- `sounds/voice_over/locales/de/garden_hint_plot_gentle.ogg`
- `sounds/voice_over/locales/de/garden_hint_plot_strong.ogg`
- `sounds/voice_over/locales/de/garden_hint_winter_gentle.ogg`
- `sounds/voice_over/locales/de/garden_hint_winter_strong.ogg`
- `sounds/voice_over/locales/de/milking_complete_0.ogg`
- `sounds/voice_over/locales/de/milking_complete_1.ogg`
- `sounds/voice_over/locales/de/milking_complete_2.ogg`
- `sounds/voice_over/locales/de/milking_complete_3.ogg`
- `sounds/voice_over/locales/de/milking_complete_4.ogg`
- `sounds/voice_over/locales/de/milking_hint_cow_gentle.ogg`
- `sounds/voice_over/locales/de/milking_hint_cow_strong.ogg`
- `sounds/voice_over/locales/de/milking_hint_gentle.ogg`
- `sounds/voice_over/locales/de/milking_hint_strong.ogg`
- `sounds/voice_over/locales/de/milking_pet_hint_gentle.ogg`
- `sounds/voice_over/locales/de/milking_pet_hint_strong.ogg`
- `sounds/voice_over/locales/en-US/santa_full_greeting.ogg`
- `sounds/voice_over/locales/es-US/santa_full_greeting.ogg`
- `sounds/voice_over/locales/es/brushing_complete_0.ogg`
- `sounds/voice_over/locales/es/brushing_complete_1.ogg`
- `sounds/voice_over/locales/es/brushing_complete_2.ogg`
- `sounds/voice_over/locales/es/brushing_complete_3.ogg`
- `sounds/voice_over/locales/es/brushing_complete_4.ogg`
- `sounds/voice_over/locales/es/brushing_hint_gentle.ogg`
- `sounds/voice_over/locales/es/brushing_hint_strong.ogg`
- `sounds/voice_over/locales/es/brushing_hint_tool_gentle.ogg`
- `sounds/voice_over/locales/es/brushing_hint_tool_strong.ogg`
- `sounds/voice_over/locales/es/eggs_complete_0.ogg`
- `sounds/voice_over/locales/es/eggs_complete_1.ogg`
- `sounds/voice_over/locales/es/eggs_complete_2.ogg`
- `sounds/voice_over/locales/es/eggs_complete_3.ogg`
- `sounds/voice_over/locales/es/eggs_complete_4.ogg`
- `sounds/voice_over/locales/es/eggs_hint_basket_gentle.ogg`
- `sounds/voice_over/locales/es/eggs_hint_basket_strong.ogg`
- `sounds/voice_over/locales/es/eggs_hint_gentle.ogg`
- `sounds/voice_over/locales/es/eggs_hint_strong.ogg`
- `sounds/voice_over/locales/es/feeding_complete_0.ogg`
- `sounds/voice_over/locales/es/feeding_complete_1.ogg`
- `sounds/voice_over/locales/es/feeding_complete_2.ogg`
- `sounds/voice_over/locales/es/feeding_complete_3.ogg`
- `sounds/voice_over/locales/es/feeding_complete_4.ogg`
- `sounds/voice_over/locales/es/feeding_hint_gentle.ogg`
- `sounds/voice_over/locales/es/feeding_hint_strong.ogg`
- `sounds/voice_over/locales/es/garden_complete_0.ogg`
- `sounds/voice_over/locales/es/garden_complete_1.ogg`
- `sounds/voice_over/locales/es/garden_complete_2.ogg`
- `sounds/voice_over/locales/es/garden_complete_3.ogg`
- `sounds/voice_over/locales/es/garden_complete_4.ogg`
- `sounds/voice_over/locales/es/garden_hint_plot_gentle.ogg`
- `sounds/voice_over/locales/es/garden_hint_plot_strong.ogg`
- `sounds/voice_over/locales/es/garden_hint_winter_gentle.ogg`
- `sounds/voice_over/locales/es/garden_hint_winter_strong.ogg`
- `sounds/voice_over/locales/es/milking_complete_0.ogg`
- `sounds/voice_over/locales/es/milking_complete_1.ogg`
- `sounds/voice_over/locales/es/milking_complete_2.ogg`
- `sounds/voice_over/locales/es/milking_complete_3.ogg`
- `sounds/voice_over/locales/es/milking_complete_4.ogg`
- `sounds/voice_over/locales/es/milking_hint_cow_gentle.ogg`
- `sounds/voice_over/locales/es/milking_hint_cow_strong.ogg`
- `sounds/voice_over/locales/es/milking_hint_gentle.ogg`
- `sounds/voice_over/locales/es/milking_hint_strong.ogg`
- `sounds/voice_over/locales/es/milking_pet_hint_gentle.ogg`
- `sounds/voice_over/locales/es/milking_pet_hint_strong.ogg`
- `sounds/voice_over/locales/fr-FR/santa_full_greeting.ogg`
- `sounds/voice_over/locales/fr/brushing_complete_0.ogg`
- `sounds/voice_over/locales/fr/brushing_complete_1.ogg`
- `sounds/voice_over/locales/fr/brushing_complete_2.ogg`
- `sounds/voice_over/locales/fr/brushing_complete_3.ogg`
- `sounds/voice_over/locales/fr/brushing_complete_4.ogg`
- `sounds/voice_over/locales/fr/brushing_hint_gentle.ogg`
- `sounds/voice_over/locales/fr/brushing_hint_strong.ogg`
- `sounds/voice_over/locales/fr/brushing_hint_tool_gentle.ogg`
- `sounds/voice_over/locales/fr/brushing_hint_tool_strong.ogg`
- `sounds/voice_over/locales/fr/eggs_complete_0.ogg`
- `sounds/voice_over/locales/fr/eggs_complete_1.ogg`
- `sounds/voice_over/locales/fr/eggs_complete_2.ogg`
- `sounds/voice_over/locales/fr/eggs_complete_3.ogg`
- `sounds/voice_over/locales/fr/eggs_complete_4.ogg`
- `sounds/voice_over/locales/fr/eggs_hint_basket_gentle.ogg`
- `sounds/voice_over/locales/fr/eggs_hint_basket_strong.ogg`
- `sounds/voice_over/locales/fr/eggs_hint_gentle.ogg`
- `sounds/voice_over/locales/fr/eggs_hint_strong.ogg`
- `sounds/voice_over/locales/fr/feeding_complete_0.ogg`
- `sounds/voice_over/locales/fr/feeding_complete_1.ogg`
- `sounds/voice_over/locales/fr/feeding_complete_2.ogg`
- `sounds/voice_over/locales/fr/feeding_complete_3.ogg`
- `sounds/voice_over/locales/fr/feeding_complete_4.ogg`
- `sounds/voice_over/locales/fr/feeding_hint_gentle.ogg`
- `sounds/voice_over/locales/fr/feeding_hint_strong.ogg`
- `sounds/voice_over/locales/fr/garden_complete_0.ogg`
- `sounds/voice_over/locales/fr/garden_complete_1.ogg`
- `sounds/voice_over/locales/fr/garden_complete_2.ogg`
- `sounds/voice_over/locales/fr/garden_complete_3.ogg`
- `sounds/voice_over/locales/fr/garden_complete_4.ogg`
- `sounds/voice_over/locales/fr/garden_hint_plot_gentle.ogg`
- `sounds/voice_over/locales/fr/garden_hint_plot_strong.ogg`
- `sounds/voice_over/locales/fr/garden_hint_winter_gentle.ogg`
- `sounds/voice_over/locales/fr/garden_hint_winter_strong.ogg`
- `sounds/voice_over/locales/fr/milking_complete_0.ogg`
- `sounds/voice_over/locales/fr/milking_complete_1.ogg`
- `sounds/voice_over/locales/fr/milking_complete_2.ogg`
- `sounds/voice_over/locales/fr/milking_complete_3.ogg`
- `sounds/voice_over/locales/fr/milking_complete_4.ogg`
- `sounds/voice_over/locales/fr/milking_hint_cow_gentle.ogg`
- `sounds/voice_over/locales/fr/milking_hint_cow_strong.ogg`
- `sounds/voice_over/locales/fr/milking_hint_gentle.ogg`
- `sounds/voice_over/locales/fr/milking_hint_strong.ogg`
- `sounds/voice_over/locales/fr/milking_pet_hint_gentle.ogg`
- `sounds/voice_over/locales/fr/milking_pet_hint_strong.ogg`
- `sounds/voice_over/locales/hi/brushing_complete_0.ogg`
- `sounds/voice_over/locales/hi/brushing_complete_1.ogg`
- `sounds/voice_over/locales/hi/brushing_complete_2.ogg`
- `sounds/voice_over/locales/hi/brushing_complete_3.ogg`
- `sounds/voice_over/locales/hi/brushing_complete_4.ogg`
- `sounds/voice_over/locales/hi/brushing_hint_gentle.ogg`
- `sounds/voice_over/locales/hi/brushing_hint_strong.ogg`
- `sounds/voice_over/locales/hi/brushing_hint_tool_gentle.ogg`
- `sounds/voice_over/locales/hi/brushing_hint_tool_strong.ogg`
- `sounds/voice_over/locales/hi/eggs_complete_0.ogg`
- `sounds/voice_over/locales/hi/eggs_complete_1.ogg`
- `sounds/voice_over/locales/hi/eggs_complete_2.ogg`
- `sounds/voice_over/locales/hi/eggs_complete_3.ogg`
- `sounds/voice_over/locales/hi/eggs_complete_4.ogg`
- `sounds/voice_over/locales/hi/eggs_hint_basket_gentle.ogg`
- `sounds/voice_over/locales/hi/eggs_hint_basket_strong.ogg`
- `sounds/voice_over/locales/hi/eggs_hint_gentle.ogg`
- `sounds/voice_over/locales/hi/eggs_hint_strong.ogg`
- `sounds/voice_over/locales/hi/feeding_complete_0.ogg`
- `sounds/voice_over/locales/hi/feeding_complete_1.ogg`
- `sounds/voice_over/locales/hi/feeding_complete_2.ogg`
- `sounds/voice_over/locales/hi/feeding_complete_3.ogg`
- `sounds/voice_over/locales/hi/feeding_complete_4.ogg`
- `sounds/voice_over/locales/hi/feeding_hint_gentle.ogg`
- `sounds/voice_over/locales/hi/feeding_hint_strong.ogg`
- `sounds/voice_over/locales/hi/garden_complete_0.ogg`
- `sounds/voice_over/locales/hi/garden_complete_1.ogg`
- `sounds/voice_over/locales/hi/garden_complete_2.ogg`
- `sounds/voice_over/locales/hi/garden_complete_3.ogg`
- `sounds/voice_over/locales/hi/garden_complete_4.ogg`
- `sounds/voice_over/locales/hi/garden_hint_plot_gentle.ogg`
- `sounds/voice_over/locales/hi/garden_hint_plot_strong.ogg`
- `sounds/voice_over/locales/hi/garden_hint_winter_gentle.ogg`
- `sounds/voice_over/locales/hi/garden_hint_winter_strong.ogg`
- `sounds/voice_over/locales/hi/milking_complete_0.ogg`
- `sounds/voice_over/locales/hi/milking_complete_1.ogg`
- `sounds/voice_over/locales/hi/milking_complete_2.ogg`
- `sounds/voice_over/locales/hi/milking_complete_3.ogg`
- `sounds/voice_over/locales/hi/milking_complete_4.ogg`
- `sounds/voice_over/locales/hi/milking_hint_cow_gentle.ogg`
- `sounds/voice_over/locales/hi/milking_hint_cow_strong.ogg`
- `sounds/voice_over/locales/hi/milking_hint_gentle.ogg`
- `sounds/voice_over/locales/hi/milking_hint_strong.ogg`
- `sounds/voice_over/locales/hi/milking_pet_hint_gentle.ogg`
- `sounds/voice_over/locales/hi/milking_pet_hint_strong.ogg`
- `sounds/voice_over/locales/it-IT/santa_full_greeting.ogg`
- `sounds/voice_over/locales/it/brushing_complete_0.ogg`
- `sounds/voice_over/locales/it/brushing_complete_1.ogg`
- `sounds/voice_over/locales/it/brushing_complete_2.ogg`
- `sounds/voice_over/locales/it/brushing_complete_3.ogg`
- `sounds/voice_over/locales/it/brushing_complete_4.ogg`
- `sounds/voice_over/locales/it/brushing_hint_gentle.ogg`
- `sounds/voice_over/locales/it/brushing_hint_strong.ogg`
- `sounds/voice_over/locales/it/brushing_hint_tool_gentle.ogg`
- `sounds/voice_over/locales/it/brushing_hint_tool_strong.ogg`
- `sounds/voice_over/locales/it/eggs_complete_0.ogg`
- `sounds/voice_over/locales/it/eggs_complete_1.ogg`
- `sounds/voice_over/locales/it/eggs_complete_2.ogg`
- `sounds/voice_over/locales/it/eggs_complete_3.ogg`
- `sounds/voice_over/locales/it/eggs_complete_4.ogg`
- `sounds/voice_over/locales/it/eggs_hint_basket_gentle.ogg`
- `sounds/voice_over/locales/it/eggs_hint_basket_strong.ogg`
- `sounds/voice_over/locales/it/eggs_hint_gentle.ogg`
- `sounds/voice_over/locales/it/eggs_hint_strong.ogg`
- `sounds/voice_over/locales/it/feeding_complete_0.ogg`
- `sounds/voice_over/locales/it/feeding_complete_1.ogg`
- `sounds/voice_over/locales/it/feeding_complete_2.ogg`
- `sounds/voice_over/locales/it/feeding_complete_3.ogg`
- `sounds/voice_over/locales/it/feeding_complete_4.ogg`
- `sounds/voice_over/locales/it/feeding_hint_gentle.ogg`
- `sounds/voice_over/locales/it/feeding_hint_strong.ogg`
- `sounds/voice_over/locales/it/garden_complete_0.ogg`
- `sounds/voice_over/locales/it/garden_complete_1.ogg`
- `sounds/voice_over/locales/it/garden_complete_2.ogg`
- `sounds/voice_over/locales/it/garden_complete_3.ogg`
- `sounds/voice_over/locales/it/garden_complete_4.ogg`
- `sounds/voice_over/locales/it/garden_hint_plot_gentle.ogg`
- `sounds/voice_over/locales/it/garden_hint_plot_strong.ogg`
- `sounds/voice_over/locales/it/garden_hint_winter_gentle.ogg`
- `sounds/voice_over/locales/it/garden_hint_winter_strong.ogg`
- `sounds/voice_over/locales/it/milking_complete_0.ogg`
- `sounds/voice_over/locales/it/milking_complete_1.ogg`
- `sounds/voice_over/locales/it/milking_complete_2.ogg`
- `sounds/voice_over/locales/it/milking_complete_3.ogg`
- `sounds/voice_over/locales/it/milking_complete_4.ogg`
- `sounds/voice_over/locales/it/milking_hint_cow_gentle.ogg`
- `sounds/voice_over/locales/it/milking_hint_cow_strong.ogg`
- `sounds/voice_over/locales/it/milking_hint_gentle.ogg`
- `sounds/voice_over/locales/it/milking_hint_strong.ogg`
- `sounds/voice_over/locales/it/milking_pet_hint_gentle.ogg`
- `sounds/voice_over/locales/it/milking_pet_hint_strong.ogg`
- `sounds/voice_over/locales/ja/brushing_complete_0.ogg`
- `sounds/voice_over/locales/ja/brushing_complete_1.ogg`
- `sounds/voice_over/locales/ja/brushing_complete_2.ogg`
- `sounds/voice_over/locales/ja/brushing_complete_3.ogg`
- `sounds/voice_over/locales/ja/brushing_complete_4.ogg`
- `sounds/voice_over/locales/ja/brushing_hint_gentle.ogg`
- `sounds/voice_over/locales/ja/brushing_hint_strong.ogg`
- `sounds/voice_over/locales/ja/brushing_hint_tool_gentle.ogg`
- `sounds/voice_over/locales/ja/brushing_hint_tool_strong.ogg`
- `sounds/voice_over/locales/ja/eggs_complete_0.ogg`
- `sounds/voice_over/locales/ja/eggs_complete_1.ogg`
- `sounds/voice_over/locales/ja/eggs_complete_2.ogg`
- `sounds/voice_over/locales/ja/eggs_complete_3.ogg`
- `sounds/voice_over/locales/ja/eggs_complete_4.ogg`
- `sounds/voice_over/locales/ja/eggs_hint_basket_gentle.ogg`
- `sounds/voice_over/locales/ja/eggs_hint_basket_strong.ogg`
- `sounds/voice_over/locales/ja/eggs_hint_gentle.ogg`
- `sounds/voice_over/locales/ja/eggs_hint_strong.ogg`
- `sounds/voice_over/locales/ja/feeding_complete_0.ogg`
- `sounds/voice_over/locales/ja/feeding_complete_1.ogg`
- `sounds/voice_over/locales/ja/feeding_complete_2.ogg`
- `sounds/voice_over/locales/ja/feeding_complete_3.ogg`
- `sounds/voice_over/locales/ja/feeding_complete_4.ogg`
- `sounds/voice_over/locales/ja/feeding_hint_gentle.ogg`
- `sounds/voice_over/locales/ja/feeding_hint_strong.ogg`
- `sounds/voice_over/locales/ja/garden_complete_0.ogg`
- `sounds/voice_over/locales/ja/garden_complete_1.ogg`
- `sounds/voice_over/locales/ja/garden_complete_2.ogg`
- `sounds/voice_over/locales/ja/garden_complete_3.ogg`
- `sounds/voice_over/locales/ja/garden_complete_4.ogg`
- `sounds/voice_over/locales/ja/garden_hint_plot_gentle.ogg`
- `sounds/voice_over/locales/ja/garden_hint_plot_strong.ogg`
- `sounds/voice_over/locales/ja/garden_hint_winter_gentle.ogg`
- `sounds/voice_over/locales/ja/garden_hint_winter_strong.ogg`
- `sounds/voice_over/locales/ja/milking_complete_0.ogg`
- `sounds/voice_over/locales/ja/milking_complete_1.ogg`
- `sounds/voice_over/locales/ja/milking_complete_2.ogg`
- `sounds/voice_over/locales/ja/milking_complete_3.ogg`
- `sounds/voice_over/locales/ja/milking_complete_4.ogg`
- `sounds/voice_over/locales/ja/milking_hint_cow_gentle.ogg`
- `sounds/voice_over/locales/ja/milking_hint_cow_strong.ogg`
- `sounds/voice_over/locales/ja/milking_hint_gentle.ogg`
- `sounds/voice_over/locales/ja/milking_hint_strong.ogg`
- `sounds/voice_over/locales/ja/milking_pet_hint_gentle.ogg`
- `sounds/voice_over/locales/ja/milking_pet_hint_strong.ogg`
- `sounds/voice_over/locales/ko/brushing_complete_0.ogg`
- `sounds/voice_over/locales/ko/brushing_complete_1.ogg`
- `sounds/voice_over/locales/ko/brushing_complete_2.ogg`
- `sounds/voice_over/locales/ko/brushing_complete_3.ogg`
- `sounds/voice_over/locales/ko/brushing_complete_4.ogg`
- `sounds/voice_over/locales/ko/brushing_hint_gentle.ogg`
- `sounds/voice_over/locales/ko/brushing_hint_strong.ogg`
- `sounds/voice_over/locales/ko/brushing_hint_tool_gentle.ogg`
- `sounds/voice_over/locales/ko/brushing_hint_tool_strong.ogg`
- `sounds/voice_over/locales/ko/eggs_complete_0.ogg`
- `sounds/voice_over/locales/ko/eggs_complete_1.ogg`
- `sounds/voice_over/locales/ko/eggs_complete_2.ogg`
- `sounds/voice_over/locales/ko/eggs_complete_3.ogg`
- `sounds/voice_over/locales/ko/eggs_complete_4.ogg`
- `sounds/voice_over/locales/ko/eggs_hint_basket_gentle.ogg`
- `sounds/voice_over/locales/ko/eggs_hint_basket_strong.ogg`
- `sounds/voice_over/locales/ko/eggs_hint_gentle.ogg`
- `sounds/voice_over/locales/ko/eggs_hint_strong.ogg`
- `sounds/voice_over/locales/ko/feeding_complete_0.ogg`
- `sounds/voice_over/locales/ko/feeding_complete_1.ogg`
- `sounds/voice_over/locales/ko/feeding_complete_2.ogg`
- `sounds/voice_over/locales/ko/feeding_complete_3.ogg`
- `sounds/voice_over/locales/ko/feeding_complete_4.ogg`
- `sounds/voice_over/locales/ko/feeding_hint_gentle.ogg`
- `sounds/voice_over/locales/ko/feeding_hint_strong.ogg`
- `sounds/voice_over/locales/ko/garden_complete_0.ogg`
- `sounds/voice_over/locales/ko/garden_complete_1.ogg`
- `sounds/voice_over/locales/ko/garden_complete_2.ogg`
- `sounds/voice_over/locales/ko/garden_complete_3.ogg`
- `sounds/voice_over/locales/ko/garden_complete_4.ogg`
- `sounds/voice_over/locales/ko/garden_hint_plot_gentle.ogg`
- `sounds/voice_over/locales/ko/garden_hint_plot_strong.ogg`
- `sounds/voice_over/locales/ko/garden_hint_winter_gentle.ogg`
- `sounds/voice_over/locales/ko/garden_hint_winter_strong.ogg`
- `sounds/voice_over/locales/ko/milking_complete_0.ogg`
- `sounds/voice_over/locales/ko/milking_complete_1.ogg`
- `sounds/voice_over/locales/ko/milking_complete_2.ogg`
- `sounds/voice_over/locales/ko/milking_complete_3.ogg`
- `sounds/voice_over/locales/ko/milking_complete_4.ogg`
- `sounds/voice_over/locales/ko/milking_hint_cow_gentle.ogg`
- `sounds/voice_over/locales/ko/milking_hint_cow_strong.ogg`
- `sounds/voice_over/locales/ko/milking_hint_gentle.ogg`
- `sounds/voice_over/locales/ko/milking_hint_strong.ogg`
- `sounds/voice_over/locales/ko/milking_pet_hint_gentle.ogg`
- `sounds/voice_over/locales/ko/milking_pet_hint_strong.ogg`
- `sounds/voice_over/locales/pt-BR/brushing_complete_0.ogg`
- `sounds/voice_over/locales/pt-BR/brushing_complete_1.ogg`
- `sounds/voice_over/locales/pt-BR/brushing_complete_2.ogg`
- `sounds/voice_over/locales/pt-BR/brushing_complete_3.ogg`
- `sounds/voice_over/locales/pt-BR/brushing_complete_4.ogg`
- `sounds/voice_over/locales/pt-BR/brushing_hint_gentle.ogg`
- `sounds/voice_over/locales/pt-BR/brushing_hint_strong.ogg`
- `sounds/voice_over/locales/pt-BR/brushing_hint_tool_gentle.ogg`
- `sounds/voice_over/locales/pt-BR/brushing_hint_tool_strong.ogg`
- `sounds/voice_over/locales/pt-BR/eggs_complete_0.ogg`
- `sounds/voice_over/locales/pt-BR/eggs_complete_1.ogg`
- `sounds/voice_over/locales/pt-BR/eggs_complete_2.ogg`
- `sounds/voice_over/locales/pt-BR/eggs_complete_3.ogg`
- `sounds/voice_over/locales/pt-BR/eggs_complete_4.ogg`
- `sounds/voice_over/locales/pt-BR/eggs_hint_basket_gentle.ogg`
- `sounds/voice_over/locales/pt-BR/eggs_hint_basket_strong.ogg`
- `sounds/voice_over/locales/pt-BR/eggs_hint_gentle.ogg`
- `sounds/voice_over/locales/pt-BR/eggs_hint_strong.ogg`
- `sounds/voice_over/locales/pt-BR/feeding_complete_0.ogg`
- `sounds/voice_over/locales/pt-BR/feeding_complete_1.ogg`
- `sounds/voice_over/locales/pt-BR/feeding_complete_2.ogg`
- `sounds/voice_over/locales/pt-BR/feeding_complete_3.ogg`
- `sounds/voice_over/locales/pt-BR/feeding_complete_4.ogg`
- `sounds/voice_over/locales/pt-BR/feeding_hint_gentle.ogg`
- `sounds/voice_over/locales/pt-BR/feeding_hint_strong.ogg`
- `sounds/voice_over/locales/pt-BR/garden_complete_0.ogg`
- `sounds/voice_over/locales/pt-BR/garden_complete_1.ogg`
- `sounds/voice_over/locales/pt-BR/garden_complete_2.ogg`
- `sounds/voice_over/locales/pt-BR/garden_complete_3.ogg`
- `sounds/voice_over/locales/pt-BR/garden_complete_4.ogg`
- `sounds/voice_over/locales/pt-BR/garden_hint_plot_gentle.ogg`
- `sounds/voice_over/locales/pt-BR/garden_hint_plot_strong.ogg`
- `sounds/voice_over/locales/pt-BR/garden_hint_winter_gentle.ogg`
- `sounds/voice_over/locales/pt-BR/garden_hint_winter_strong.ogg`
- `sounds/voice_over/locales/pt-BR/milking_complete_0.ogg`
- `sounds/voice_over/locales/pt-BR/milking_complete_1.ogg`
- `sounds/voice_over/locales/pt-BR/milking_complete_2.ogg`
- `sounds/voice_over/locales/pt-BR/milking_complete_3.ogg`
- `sounds/voice_over/locales/pt-BR/milking_complete_4.ogg`
- `sounds/voice_over/locales/pt-BR/milking_hint_cow_gentle.ogg`
- `sounds/voice_over/locales/pt-BR/milking_hint_cow_strong.ogg`
- `sounds/voice_over/locales/pt-BR/milking_hint_gentle.ogg`
- `sounds/voice_over/locales/pt-BR/milking_hint_strong.ogg`
- `sounds/voice_over/locales/pt-BR/milking_pet_hint_gentle.ogg`
- `sounds/voice_over/locales/pt-BR/milking_pet_hint_strong.ogg`
- `sounds/voice_over/locales/pt-BR/santa_full_greeting.ogg`
- `sounds/voice_over/locales/zh-CN/brushing_complete_0.ogg`
- `sounds/voice_over/locales/zh-CN/brushing_complete_1.ogg`
- `sounds/voice_over/locales/zh-CN/brushing_complete_2.ogg`
- `sounds/voice_over/locales/zh-CN/brushing_complete_3.ogg`
- `sounds/voice_over/locales/zh-CN/brushing_complete_4.ogg`
- `sounds/voice_over/locales/zh-CN/brushing_hint_gentle.ogg`
- `sounds/voice_over/locales/zh-CN/brushing_hint_strong.ogg`
- `sounds/voice_over/locales/zh-CN/brushing_hint_tool_gentle.ogg`
- `sounds/voice_over/locales/zh-CN/brushing_hint_tool_strong.ogg`
- `sounds/voice_over/locales/zh-CN/eggs_complete_0.ogg`
- `sounds/voice_over/locales/zh-CN/eggs_complete_1.ogg`
- `sounds/voice_over/locales/zh-CN/eggs_complete_2.ogg`
- `sounds/voice_over/locales/zh-CN/eggs_complete_3.ogg`
- `sounds/voice_over/locales/zh-CN/eggs_complete_4.ogg`
- `sounds/voice_over/locales/zh-CN/eggs_hint_basket_gentle.ogg`
- `sounds/voice_over/locales/zh-CN/eggs_hint_basket_strong.ogg`
- `sounds/voice_over/locales/zh-CN/eggs_hint_gentle.ogg`
- `sounds/voice_over/locales/zh-CN/eggs_hint_strong.ogg`
- `sounds/voice_over/locales/zh-CN/feeding_complete_0.ogg`
- `sounds/voice_over/locales/zh-CN/feeding_complete_1.ogg`
- `sounds/voice_over/locales/zh-CN/feeding_complete_2.ogg`
- `sounds/voice_over/locales/zh-CN/feeding_complete_3.ogg`
- `sounds/voice_over/locales/zh-CN/feeding_complete_4.ogg`
- `sounds/voice_over/locales/zh-CN/feeding_hint_gentle.ogg`
- `sounds/voice_over/locales/zh-CN/feeding_hint_strong.ogg`
- `sounds/voice_over/locales/zh-CN/garden_complete_0.ogg`
- `sounds/voice_over/locales/zh-CN/garden_complete_1.ogg`
- `sounds/voice_over/locales/zh-CN/garden_complete_2.ogg`
- `sounds/voice_over/locales/zh-CN/garden_complete_3.ogg`
- `sounds/voice_over/locales/zh-CN/garden_complete_4.ogg`
- `sounds/voice_over/locales/zh-CN/garden_hint_plot_gentle.ogg`
- `sounds/voice_over/locales/zh-CN/garden_hint_plot_strong.ogg`
- `sounds/voice_over/locales/zh-CN/garden_hint_winter_gentle.ogg`
- `sounds/voice_over/locales/zh-CN/garden_hint_winter_strong.ogg`
- `sounds/voice_over/locales/zh-CN/milking_complete_0.ogg`
- `sounds/voice_over/locales/zh-CN/milking_complete_1.ogg`
- `sounds/voice_over/locales/zh-CN/milking_complete_2.ogg`
- `sounds/voice_over/locales/zh-CN/milking_complete_3.ogg`
- `sounds/voice_over/locales/zh-CN/milking_complete_4.ogg`
- `sounds/voice_over/locales/zh-CN/milking_hint_cow_gentle.ogg`
- `sounds/voice_over/locales/zh-CN/milking_hint_cow_strong.ogg`
- `sounds/voice_over/locales/zh-CN/milking_hint_gentle.ogg`
- `sounds/voice_over/locales/zh-CN/milking_hint_strong.ogg`
- `sounds/voice_over/locales/zh-CN/milking_pet_hint_gentle.ogg`
- `sounds/voice_over/locales/zh-CN/milking_pet_hint_strong.ogg`
- `sounds/voice_over/milking_complete_0.ogg`
- `sounds/voice_over/milking_complete_1.ogg`
- `sounds/voice_over/milking_complete_2.ogg`
- `sounds/voice_over/milking_complete_3.ogg`
- `sounds/voice_over/milking_complete_4.ogg`
- `sounds/voice_over/milking_hint_cow_gentle.ogg`
- `sounds/voice_over/milking_hint_cow_strong.ogg`
- `sounds/voice_over/milking_hint_gentle.ogg`
- `sounds/voice_over/milking_hint_strong.ogg`
- `sounds/voice_over/milking_pet_hint_gentle.ogg`
- `sounds/voice_over/milking_pet_hint_strong.ogg`

### Artwork configuration/metadata (1)

- `art/backgrounds/farmyard_layers/farmyard_layers_manifest.json`

### Bundled third-party Noto font (not hand-drawn or AI-generated) (6)

- `art/fonts/NotoSans-Variable.ttf`
- `art/fonts/NotoSansArabic-Variable.ttf`
- `art/fonts/NotoSansDevanagari-Variable.ttf`
- `art/fonts/NotoSansJP-Variable.ttf`
- `art/fonts/NotoSansKR-Variable.ttf`
- `art/fonts/NotoSansSC-Variable.ttf`

### Font attribution/licensing text (1)

- `art/fonts/NOTICE.txt`

### Privacy-policy text (not a rendered asset) (11)

- `resources/privacy_policy.txt`
- `resources/privacy_policy_ar.txt`
- `resources/privacy_policy_de.txt`
- `resources/privacy_policy_es.txt`
- `resources/privacy_policy_fr.txt`
- `resources/privacy_policy_hi.txt`
- `resources/privacy_policy_it.txt`
- `resources/privacy_policy_ja.txt`
- `resources/privacy_policy_ko.txt`
- `resources/privacy_policy_pt_br.txt`
- `resources/privacy_policy_zh_cn.txt`

### Procedurally drawn artwork (the current generator writes this path; stored pixels differ from a fresh generation) (121)

- `art/animals/chicken_blinking.png`
- `art/animals/chicken_celebrating.png`
- `art/animals/chicken_eating.png`
- `art/animals/chicken_excited.png`
- `art/animals/chicken_happy.png`
- `art/animals/chicken_idle.png`
- `art/animals/chicken_states_sheet.png`
- `art/animals/chicken_walking.png`
- `art/animals/cow_blinking.png`
- `art/animals/cow_celebrating.png`
- `art/animals/cow_eating.png`
- `art/animals/cow_excited.png`
- `art/animals/cow_happy.png`
- `art/animals/cow_idle.png`
- `art/animals/cow_states_sheet.png`
- `art/animals/cow_walking.png`
- `art/animals/goat_blinking.png`
- `art/animals/goat_celebrating.png`
- `art/animals/goat_eating.png`
- `art/animals/goat_excited.png`
- `art/animals/goat_happy.png`
- `art/animals/goat_idle.png`
- `art/animals/goat_states_sheet.png`
- `art/animals/goat_walking.png`
- `art/animals/hub_feed_chicken.png`
- `art/animals/hub_feed_goat.png`
- `art/animals/hub_feed_pig.png`
- `art/animals/hub_feed_sheep.png`
- `art/animals/pig_blinking.png`
- `art/animals/pig_celebrating.png`
- `art/animals/pig_eating.png`
- `art/animals/pig_excited.png`
- `art/animals/pig_happy.png`
- `art/animals/pig_idle.png`
- `art/animals/pig_states_sheet.png`
- `art/animals/pig_walking.png`
- `art/animals/pony_blinking.png`
- `art/animals/pony_celebrating.png`
- `art/animals/pony_eating.png`
- `art/animals/pony_excited.png`
- `art/animals/pony_happy.png`
- `art/animals/pony_idle.png`
- `art/animals/pony_states_sheet.png`
- `art/animals/pony_walking.png`
- `art/animals/sheep_blinking.png`
- `art/animals/sheep_celebrating.png`
- `art/animals/sheep_eating.png`
- `art/animals/sheep_excited.png`
- `art/animals/sheep_happy.png`
- `art/animals/sheep_idle.png`
- `art/animals/sheep_states_sheet.png`
- `art/animals/sheep_walking.png`
- `art/backgrounds/farmyard_layers/activity_back_fence.png`
- `art/backgrounds/farmyard_layers/cow_area.png`
- `art/backgrounds/farmyard_layers/decorative_props.png`
- `art/backgrounds/farmyard_layers/garden_area.png`
- `art/backgrounds/farmyard_layers/ground_base.png`
- `art/backgrounds/farmyard_layers/paths.png`
- `art/backgrounds/farmyard_layers/sky.png`
- `art/backgrounds/start_background.png`
- `art/effects/clean_sparkle.png`
- `art/effects/dirt_smudge.png`
- `art/effects/sparkle.png`
- `art/effects/star.png`
- `art/effects/success_glow.png`
- `art/effects/water_drop.png`
- `art/garden/apple.png`
- `art/garden/carrot.png`
- `art/garden/corn.png`
- `art/garden/harvest_ready.png`
- `art/garden/harvested.png`
- `art/garden/plant_growing.png`
- `art/garden/plot_tile.png`
- `art/garden/pumpkin.png`
- `art/garden/seed.png`
- `art/garden/sprout.png`
- `art/garden/strawberry.png`
- `art/garden/sunflower.png`
- `art/garden/tomato.png`
- `art/garden/turnip.png`
- `art/garden/wet_soil_overlay.png`
- `art/props/chicken_coop.png`
- `art/props/chicken_nest_hay_pocket.png`
- `art/props/decoration_duck_pond.png`
- `art/props/decoration_flower_path.png`
- `art/props/decoration_orchard_tree.png`
- `art/props/decoration_windmill.png`
- `art/props/decoration_windmill_fall.png`
- `art/props/decoration_windmill_spring.png`
- `art/props/decoration_windmill_summer.png`
- `art/props/decoration_windmill_winter.png`
- `art/props/egg.png`
- `art/props/egg_basket.png`
- `art/props/feed_bag.png`
- `art/props/feed_cart.png`
- `art/props/feed_pile.png`
- `art/props/feed_pour.png`
- `art/props/feeding_station_back.png`
- `art/props/feeding_station_front.png`
- `art/props/grooming_brush.png`
- `art/props/grooming_station_back.png`
- `art/props/grooming_station_front.png`
- `art/props/hay_bale.png`
- `art/props/hub_animal_pen_front.png`
- `art/props/hub_feed_pen.png`
- `art/props/hub_feed_trough_front.png`
- `art/props/hub_grooming_stalls.png`
- `art/props/milk_bucket.png`
- `art/props/watering_can.png`
- `art/ui/app_icon_192.png`
- `art/ui/app_icon_adaptive_background_432.png`
- `art/ui/app_icon_adaptive_foreground_432.png`
- `art/ui/app_icon_adaptive_monochrome_432.png`
- `art/ui/back_button.png`
- `art/ui/next_day_icon.png`
- `art/ui/season_fall_leaf.png`
- `art/ui/season_spring_seedling.png`
- `art/ui/season_summer_sun.png`
- `art/ui/season_winter_snowflake.png`
- `art/ui/settings_button.png`
- `art/ui/title_banner.png`

### Sound effect / source audio (per-file origin is not documented; not attributed to AI) (31)

- `sounds/bee_buzz.wav`
- `sounds/brush.ogg`
- `sounds/chicken_cluck_variant_1.ogg`
- `sounds/chicken_cluck_variant_2.ogg`
- `sounds/chicken_cluck_variant_3.ogg`
- `sounds/chicken_cluck_variant_4.ogg`
- `sounds/chicken_cluck_variant_5.ogg`
- `sounds/complete.ogg`
- `sounds/cow_moo.wav`
- `sounds/duck_pond_note_a.wav`
- `sounds/duck_pond_note_c.wav`
- `sounds/duck_pond_note_e.wav`
- `sounds/duck_pond_note_g.wav`
- `sounds/duck_quack.wav`
- `sounds/eggcollect.wav`
- `sounds/feed.wav`
- `sounds/harvest.wav`
- `sounds/milk.ogg`
- `sounds/next_day.wav`
- `sounds/night_crickets_clip_1.ogg`
- `sounds/night_crickets_clip_2.ogg`
- `sounds/night_crickets_clip_3.ogg`
- `sounds/owl_hoot_variant_1.ogg`
- `sounds/owl_hoot_variant_2.ogg`
- `sounds/owl_hoot_variant_3.ogg`
- `sounds/santa_bells.wav`
- `sounds/santa_ho_ho_variant_1.ogg`
- `sounds/santa_ho_ho_variant_2.ogg`
- `sounds/santa_ho_ho_variant_3.ogg`
- `sounds/tap.wav`
- `sounds/water.ogg`

### Sound-design prompt text (not a rendered asset) (5)

- `art/audio_prompts/brush_swish_prompt.txt`
- `art/audio_prompts/chicken_cluck_prompt.txt`
- `art/audio_prompts/completion_chime_prompt.txt`
- `art/audio_prompts/feed_munch_prompt.txt`
- `art/audio_prompts/tap_pop_prompt.txt`

### Translation or voice-prompt text data (translation source is not recorded) (23)

- `localization/translations/ar.json`
- `localization/translations/de.json`
- `localization/translations/en.json`
- `localization/translations/es.json`
- `localization/translations/fr.json`
- `localization/translations/hi.json`
- `localization/translations/it.json`
- `localization/translations/ja.json`
- `localization/translations/ko.json`
- `localization/translations/pt_br.json`
- `localization/translations/zh_cn.json`
- `localization/voice_prompts/ar.json`
- `localization/voice_prompts/de.json`
- `localization/voice_prompts/en.json`
- `localization/voice_prompts/es.json`
- `localization/voice_prompts/fr.json`
- `localization/voice_prompts/hi.json`
- `localization/voice_prompts/it.json`
- `localization/voice_prompts/ja.json`
- `localization/voice_prompts/ko.json`
- `localization/voice_prompts/manual_review_manifest.json`
- `localization/voice_prompts/pt_br.json`
- `localization/voice_prompts/zh_cn.json`

### Vector artwork with unrecorded source method (1)

- `icon.svg`

### Voice-line/catalog metadata (not an audio file) (12)

- `sounds/voice_over/locales/ar/voice_lines.json`
- `sounds/voice_over/locales/de/voice_lines.json`
- `sounds/voice_over/locales/en/voice_lines.json`
- `sounds/voice_over/locales/es/voice_lines.json`
- `sounds/voice_over/locales/fr/voice_lines.json`
- `sounds/voice_over/locales/hi/voice_lines.json`
- `sounds/voice_over/locales/it/voice_lines.json`
- `sounds/voice_over/locales/ja/voice_lines.json`
- `sounds/voice_over/locales/ko/voice_lines.json`
- `sounds/voice_over/locales/pt-BR/voice_lines.json`
- `sounds/voice_over/locales/zh-CN/voice_lines.json`
- `sounds/voice_over/voice_lines.json`

## Interactions

- **Title:** tap the large play button to enter the farm. When “Tap Anywhere to Play” is enabled, a tap outside the settings panel also starts. Tap the gear to open settings.
- **Farm hub:** tap a chore area to open it; tap a small animal or seasonal decoration for a reaction. Background taps can highlight or route to the next unfinished chore when the assist setting is enabled. The Next Day control advances only after the required daily chores are complete.
- **Eggs:** tap each egg; it animates into the basket and updates the collection count. Chicken taps produce a reaction.
- **Milking:** tap the cow to begin the care sequence, then tap the highlighted milking target until the bucket is full.
- **Feeding:** tap each available animal; the game selects and animates its matching food automatically. The goat appears after its unlock.
- **Brushing:** tap each available animal to brush it. The brush button can request a hint; brushing itself is tap-driven.
- **Garden / watering:** tap a plot to perform its current care step. Plot state persists across days and progresses through planting, watering/growth, and harvest, with seasonal crops.
- **Duck Pond (optional):** tap lily pads to play notes and tap interactive pond elements for reactions; it can be visited once per farm day and does not count as a required chore.
- **Mole Garden (optional):** tap the mole/holes to trigger a playful response; it does not count toward daily chore completion.
- **Settings:** tap Sound, Gameplay, or Language tabs. Sound sliders respond to horizontal drag and mute buttons toggle channels. Gameplay toggles tap-anywhere behavior and optional activity timers; timer duration chips and custom minute controls appear when enabled. Language opens a locale picker, and Privacy & Parents opens the bundled policy. Done closes settings.
- **Drag model:** no chore requires dragging. Vertical drag scrolls the settings content; horizontal drag adjusts sound sliders. The game does not expose keyboard or gamepad controls.

## Known bugs and unfinished features

- The Web build logs a Godot scene-tree error, `Condition "p_scene && p_scene->get_parent() != root" is true`, during the title-to-farm transition. The farm screen still appears and the chore scenes still open; the engine error remains unresolved.
- The exported Web pack is about 190 MB. In the fresh incognito check it took roughly 52 seconds to reach the title screen on this connection; first-load time will vary with network speed.
- The game is designed around a 1920×1080 landscape canvas. At the requested 390×844 portrait viewport, the farm composition and small HUD elements scale down substantially. These captures document the current behavior; no game-layout changes were made.
- Existing Android 15 emulator QA records gray/black rendering with SwiftShader. A physical Android device render/touch/audio review is still outstanding; emulator TTS also lacked voice data.
- Generated voice clips still need a real-device clarity and volume review. Human replacement recordings are optional and not implemented.
- Sticker collection is unfinished: legacy save fields remain, but current play does not award stickers or show a sticker badge.
- Store signing and device validation remain platform-release tasks. The Android preset is configured; iOS still requires machine-specific export and signing setup.

## Target platforms and input model

The native project targets landscape Android and iOS devices, and this review adds a static Godot Web export for desktop and mobile browsers. The tested Web build loads without a login. The current input model is touchscreen taps, with mouse input as the desktop/browser equivalent; settings also support scroll and slider drags. There is no keyboard or gamepad interaction model. The game’s layout baseline is landscape even though the requested review captures use portrait 390×844.

## Screenshots

All captures are PNGs at exactly **390×844**. The title, hub, chore scenes, and settings screens use the release Web export. Seasonal, completed-progress, and optional-activity states were selected with debug-only tester controls on a local debug export; the tester panel is hidden in those saved captures.

- **Title screen:** [`screenshots/01-title-screen.png`](screenshots/01-title-screen.png)
- **Farm overview — spring:** [`screenshots/02-farm-overview-spring.png`](screenshots/02-farm-overview-spring.png)
- **Chore — brushing:** [`screenshots/chore-brushing.png`](screenshots/chore-brushing.png)
- **Chore — eggs:** [`screenshots/chore-eggs.png`](screenshots/chore-eggs.png)
- **Chore — feeding:** [`screenshots/chore-feeding.png`](screenshots/chore-feeding.png)
- **Chore — milking:** [`screenshots/chore-milking.png`](screenshots/chore-milking.png)
- **Chore — watering:** [`screenshots/chore-watering.png`](screenshots/chore-watering.png)
- **Menu — expanded language picker:** [`screenshots/menu-language-picker.png`](screenshots/menu-language-picker.png)
- **Menu — Privacy & Parents policy:** [`screenshots/menu-privacy-parents.png`](screenshots/menu-privacy-parents.png)
- **Menu — Duck Pond timer enabled:** [`screenshots/menu-settings-duck-timer-on.png`](screenshots/menu-settings-duck-timer-on.png)
- **Menu — Gameplay tab:** [`screenshots/menu-settings-gameplay.png`](screenshots/menu-settings-gameplay.png)
- **Menu — Language tab:** [`screenshots/menu-settings-language.png`](screenshots/menu-settings-language.png)
- **Menu — Sound tab, lower controls:** [`screenshots/menu-settings-sound-scrolled.png`](screenshots/menu-settings-sound-scrolled.png)
- **Menu — Sound tab:** [`screenshots/menu-settings-sound.png`](screenshots/menu-settings-sound.png)
- **Optional activity — duck pond:** [`screenshots/optional-duck-pond.png`](screenshots/optional-duck-pond.png)
- **Optional activity — mole garden:** [`screenshots/optional-mole-garden.png`](screenshots/optional-mole-garden.png)
- **Progress — all daily chores complete:** [`screenshots/progress-all-chores-complete.png`](screenshots/progress-all-chores-complete.png)
- **Farm overview — fall:** [`screenshots/season-fall.png`](screenshots/season-fall.png)
- **Farm overview — summer:** [`screenshots/season-summer.png`](screenshots/season-summer.png)
- **Farm overview — winter:** [`screenshots/season-winter.png`](screenshots/season-winter.png)
