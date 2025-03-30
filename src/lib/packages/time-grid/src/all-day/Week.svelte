<script lang="ts">
    import { getContext } from "svelte";
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

    let { dates, resource = undefined } = $props();

    let { _events, _iEvents, _queue2, hiddenDays, resources, filterEventsWithResources, validRange } =
        getContext("state");

    let iChunks = $state([]);

    let start = $state();
    let end = $state();
    let refs = $state([]);
    let resourceFilter = $state();

    let { chunks, bgChunks, longChunks } = $derived.by(() => {
        let chunks = [];
        let bgChunks = [];
        for (let event of $_events) {
            if (event.allDay && eventIntersects(event, start, end, resourceFilter)) {
                let chunk = createEventChunk(event, start, end);
                if (bgEvent(event.display)) {
                    bgChunks.push(chunk);
                } else {
                    chunks.push(chunk);
                }
            }
        }
        prepareEventChunks(bgChunks, $hiddenDays);
        let longChunks = prepareEventChunks(chunks, $hiddenDays);
        // Run reposition only when events get changed
        //reposition();                                                      //BUG
        return { chunks, bgChunks, longChunks };
    });

    _events.subscribe((v) => {
        //console.log("Week All-days event Update")

        chunks = [];
        bgChunks = [];
        for (let event of $_events) {
            if (event.allDay && eventIntersects(event, start, end, resourceFilter)) {
                let chunk = createEventChunk(event, start, end);
                if (bgEvent(event.display)) {
                    bgChunks.push(chunk);
                } else {
                    chunks.push(chunk);
                }
            }
        }

        prepareEventChunks(bgChunks, $hiddenDays);
        longChunks = prepareEventChunks(chunks, $hiddenDays);
        // Run reposition only when events get changed
        //reposition();
    });

    $effect.pre(() => {
        start = limitToRange(dates[0], $validRange);
        end = addDay(cloneDate(limitToRange(dates.at(-1), $validRange)));
    });

    $effect.pre(() => {
        resourceFilter = resource ?? ($filterEventsWithResources ? $resources : undefined);
    });

    let debounceHandle = {};
    function reposition() {
        debounce(() => runReposition(refs, dates), debounceHandle, _queue2);
    }

    $effect(() => {
        iChunks = $_iEvents.map((event) => {
            let chunk;
            if (event && event.allDay && eventIntersects(event, start, end, resource)) {
                chunk = createEventChunk(event, start, end);
                prepareEventChunks([chunk], $hiddenDays);
            } else {
                chunk = null;
            }
            return chunk;
        });
    });
</script>

{#key longChunks}
    {#each dates as date, i}
        <Day {date} {chunks} {bgChunks} {longChunks} {iChunks} {resource} bind:this={refs[i]} />
    {/each}
{/key}

<svelte:window onresize={reposition} />
