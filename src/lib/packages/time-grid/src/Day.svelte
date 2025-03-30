<script lang="ts">
    import { untrack } from "svelte";

    import { getContext } from "svelte";
    import {
        addDuration,
        bgEvent,
        cloneDate,
        createEventChunk,
        datesEqual,
        eventIntersects,
        floor,
        outsideRange,
        rect,
        setPayload,
    } from "@event-calendar/core";
    import { groupEventChunks } from "./utils";
    import Event from "./Event.svelte";
    import NowIndicator from "./NowIndicator.svelte";

    let { date, resource = undefined } = $props();

    let {
        _events,
        _iEvents,
        highlightedDates,
        nowIndicator,
        slotDuration,
        slotHeight,
        filterEventsWithResources,
        theme,
        resources,
        validRange,
        _interaction,
        _today,
        _slotTimeLimits,
    } = getContext("state");

    let el = $state();

    let isToday = $derived(datesEqual(date, $_today)),
        highlight = $derived($highlightedDates.some((d) => datesEqual(d, date))),
        disabled = $state();
    let resourceFilter = $state();
    let start = $state(),
        end = $state();

    let { chunks, bgChunks } = $derived.by(() => {
        //  if (!disabled) {
        let chunks = [];
        let bgChunks = [];
        for (let event of $_events) {
            if ((!event.allDay || bgEvent(event.display)) && eventIntersects(event, start, end, resourceFilter)) {
                let chunk_ = createEventChunk(event, start, end);

                switch (event.display) {
                    case "background":
                        bgChunks.push(chunk_);
                        break;
                    default:
                        chunks.push(chunk_);
                }
            }
        }
        groupEventChunks(chunks);
        return { chunks, bgChunks };
    });

    let iChunks = $derived.by(() => {
        let iChunks = $_iEvents.map((event) =>
            event && eventIntersects(event, start, end, resource) ? createEventChunk(event, start, end) : null,
        );

        return iChunks;
    });

    _events.subscribe((v) => {
        //console.log(`time_grid/Day.svelte: _events: ${v} `);
        if (!disabled) {
            chunks = [];
            bgChunks = [];
            for (let event of $_events) {
                if ((!event.allDay || bgEvent(event.display)) && eventIntersects(event, start, end, resourceFilter)) {
                    let chunk = createEventChunk(event, start, end);
                    switch (event.display) {
                        case "background":
                            bgChunks.push(chunk);
                            break;
                        default:
                            chunks.push(chunk);
                    }
                }
            }
            groupEventChunks(chunks);
        }
    });

    $effect.pre(() => {
        disabled = outsideRange(date, $validRange);
    });

    $effect.pre(() => {
        if (!disabled) {
            // untrack(() => {
            start = addDuration(cloneDate(date), $_slotTimeLimits.min);
            end = addDuration(cloneDate(date), $_slotTimeLimits.max);
            // });
        }
    });

    $effect.pre(() => {
        //untrack(() => {
        resourceFilter = resource ?? ($filterEventsWithResources ? $resources : undefined);
        // });
    });

    function dateFromPoint(x, y) {
        y -= rect(el).top;
        return {
            allDay: false,
            date: addDuration(
                addDuration(cloneDate(date), $_slotTimeLimits.min),
                $slotDuration,
                floor(y / $slotHeight),
            ),
            resource,
            dayEl: el,
            disabled,
        };
    }

    $effect(() => {
        if (el) {
            setPayload(el, dateFromPoint);
        }
    });
</script>

<div
    bind:this={el}
    class="{$theme.day} {$theme.weekdays?.[date.getUTCDay()]}{isToday ? ' ' + $theme.today : ''}{highlight
        ? ' ' + $theme.highlight
        : ''}{disabled ? ' ' + $theme.disabled : ''}"
    role="cell"
    onpointerdown={() => (!disabled ? $_interaction.action?.select : undefined)}
>
    <div class={$theme.bgEvents}>
        {#if !disabled}
            {#each bgChunks as chunk (chunk.event)}
                <Event {date} {chunk} />
            {/each}
        {/if}
    </div>
    <div class={$theme.events}>
        {#if !disabled}
            <!-- Pointer -->
            {#if iChunks[1]}
                <Event {date} chunk={iChunks[1]} />
            {/if}
            {#each chunks as chunk (chunk.event)}
                <Event {date} {chunk} />
            {/each}
            <!-- Drag, Resize & Select -->
            {#if iChunks[0] && !iChunks[0].event.allDay}
                <Event {date} chunk={iChunks[0]} />
            {/if}
        {/if}
    </div>
    <div class={$theme.extra}>
        <!-- Now indicator -->
        {#if $nowIndicator && isToday && !disabled}
            <NowIndicator />
        {/if}
    </div>
</div>
