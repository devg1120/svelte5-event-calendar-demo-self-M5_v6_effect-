<script lang="ts">

    import {
        height,
    } from "@event-calendar/core";

   //console.log("space:", height());
   let spaceHeight = 26;

</script>

<style>
.eventSpace {
  height : var(--SpaceHeight);
  }
</style>

<div 
  class="eventSpace" 
  style="--SpaceHeight: {spaceHeight}px"

>SPACE</div>
