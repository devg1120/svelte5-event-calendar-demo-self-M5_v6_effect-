<script lang="ts">
    import { untrack } from "svelte";

    import { getContext, tick } from "svelte";
    import {
        addDay,
        bgEvent,
        cloneDate,
        createEventChunk,
        debounce,
        eventIntersects,
        limitToRange,
        prepareEventChunks,
        runReposition,
    } from "@event-calendar/core";
    import Day from "./Day.svelte";

    let { dates } = $props();

    let {
        _events,
        _iEvents,
        _queue2,
        _hiddenEvents,
        resources,
        filterEventsWithResources,
        hiddenDays,
        theme,
        validRange,
    } = getContext("state");

    //let chunks = $state(),
    //    bgChunks = $state(),
    //    longChunks = $state(),
    let  iChunks = $state([]);

    let start = $state();
    let end = $state();
    let refs = $state([]);
    let debounceHandle = {};
    let allDaySlotHeight = 40;

    let { chunks, bgChunks , longChunks} = $derived.by(() => {

            let chunks = [];
            let bgChunks = [];
            for (let event of $_events) {
                if (eventIntersects(event, start, end, $filterEventsWithResources ? $resources : undefined)) {
                    let chunk = createEventChunk(event, start, end);
                    //if (bgEvent(event.display)) {
                        if (event.allDay) {
			    //console.log("bgChunk:", chunk)
                            bgChunks.push(chunk);
                     //   }
                    } else {
                        chunks.push(chunk);
                    }
                }
            }
            let tmp = prepareEventChunks(bgChunks, $hiddenDays);
            let longChunks = prepareEventChunks(chunks, $hiddenDays);
            // Run reposition only when events get changed
            //reposition();

           //console.log( "chanks",chunks  );
           //console.log( "bgChanks", bgChunks );
           console.log( "longChunks", longChunks );
           return { chunks, bgChunks, longChunks };


    })

    _events.subscribe((v) => {
        chunks = [];
        bgChunks = [];
        for (let event of $_events) {
            if (eventIntersects(event, start, end, $filterEventsWithResources ? $resources : undefined)) {
                let chunk = createEventChunk(event, start, end);
                if (bgEvent(event.display)) {
                    if (event.allDay) {
                        bgChunks.push(chunk);
                    }
                } else {
                    chunks.push(chunk);
                }
            }
        }
        prepareEventChunks(bgChunks, $hiddenDays);
        longChunks = prepareEventChunks(chunks, $hiddenDays);
        reposition();
    });

    $effect(() => {
        untrack(() => {
            start = limitToRange(dates[0], $validRange);
            end = addDay(cloneDate(limitToRange(dates.at(-1), $validRange)));
        });
    });

    //let debounceHandle = {};
    function reposition() {
        debounce(() => runReposition(refs, dates), debounceHandle, _queue2);
    }

/*
    $effect(() => {
        untrack(() => {
            chunks = [];
            bgChunks = [];
            for (let event of $_events) {
                if (eventIntersects(event, start, end, $filterEventsWithResources ? $resources : undefined)) {
                    let chunk = createEventChunk(event, start, end);
                    if (bgEvent(event.display)) {
                        if (event.allDay) {
                            bgChunks.push(chunk);
                        }
                    } else {
                        chunks.push(chunk);
                    }
                }
            }
            prepareEventChunks(bgChunks, $hiddenDays);
            longChunks = prepareEventChunks(chunks, $hiddenDays);
            // Run reposition only when events get changed
            reposition();
        });
    });
*/

    $effect(() => {
        iChunks = $_iEvents.map((event) => {
            let chunk;
            if (event && eventIntersects(event, start, end)) {
                chunk = createEventChunk(event, start, end);
                prepareEventChunks([chunk], $hiddenDays);
            } else {
                chunk = null;
            }
            return chunk;
        });
    });

    $effect(() => {
        untrack(() => {
            if ($_hiddenEvents) {
                // Schedule reposition during next update
                tick().then(reposition);
            }
        });
    });

    let weekRowHeight = 300;
</script>

<style>
      .weekRow { height:var(--weekRowHeight)}
</style>


<div 
  class="{$theme.days} weekRow" role="row"
  style="--weekRowHeight: {weekRowHeight}px"
>
    {#key chunks}
        {#each dates as date, i}
            <Day {date} {chunks} {bgChunks} {longChunks} {iChunks} {dates} {allDaySlotHeight} bind:this={refs[i]} />
        {/each}
    {/key}
</div>

<svelte:window onresize={reposition} />
