<script lang="ts".>
    import { stopPropagation, createBubbler } from "svelte/legacy";
    import { untrack } from "svelte";

    const bubble = createBubbler();
    import { getContext, tick } from "svelte";
    import {
        addDay,
        assign,
        cloneDate,
        createEventChunk,
        datesEqual,
        getWeekNumber,
        isFunction,
        keyEnter,
        outsideRange,
        runReposition,
        setContent,
        setPayload,
        toISOString,
        toLocalDate,
    } from "@event-calendar/core";
    import Event from "./Event.svelte";
    import EventSpace from "./EventSpace.svelte";
    import Popup from "./Popup.svelte";

    let { date, chunks, bgChunks, longChunks, iChunks = [], dates , allDaySlotHeight = 0} = $props();
    // bgChunks   allDay task
    // longChanks Day Bitween Time task
    // chunks     Time task

    let {
        date: currentDate,
        dayMaxEvents,
        highlightedDates,
        firstDay,
        moreLinkContent,
        theme,
        validRange,
        weekNumbers,
        weekNumberContent,
        _hiddenEvents,
        _intlDayCell,
        _popupDate,
        _popupChunks,
        _today,
        _interaction,
    } = getContext("state");

    let el = $state();
    let dayChunks = $state(),
        dayBgChunks = $state();
    let isToday = $derived(datesEqual(date, $_today)),
        otherMonth = $derived(date.getUTCMonth() !== $currentDate.getUTCMonth()),
        highlight = $derived($highlightedDates.some((d) => datesEqual(d, date))),
        disabled = $state();
    let hiddenEvents = $state(new Set()); // hidden events of this day
    let moreLink = $state("");
    let showPopup = $state();
    let showWeekNumber = $state();
    let weekNumber = $state();
    let refs = $state([]);


    function showMore() {
        $_popupDate = date;
    }

    function setPopupChunks() {
        let nextDay = addDay(cloneDate(date));
        let chunks = dayChunks.concat(longChunks[date.getTime()]?.chunks || []);
        $_popupChunks = chunks
            .map((chunk) => assign({}, chunk, createEventChunk(chunk.event, date, nextDay), { days: 1, dates: [date] }))
            .sort((a, b) => a.top - b.top);
    }

    export function reposition() {
        if (!disabled) {
            runReposition(refs, dayChunks);
        }
    }
/*
    let style = $derived.by(() => {
        //let style = `height:calc(${chunk.days * 100}% + ${chunk.days - 1}px);`;
        //let style = `.allDaySlot { height:calc($bgChunks.length * 90)px)}`;
        let style = `.allDaySlot { height:  90px}`;
	return style
	})
	*/
    
    $effect(() => {
        disabled = outsideRange(date, $validRange);
    });

    $effect(() => {
        untrack(() => {
            if (!disabled) {
                dayChunks = [];
                dayBgChunks = bgChunks.filter((bgChunk) => datesEqual(bgChunk.date, date));
                hiddenEvents.clear();
                hiddenEvents = hiddenEvents;
                for (let chunk of chunks) {
                    if (datesEqual(chunk.date, date)) {
                        //dayChunks.push(chunk);
			//console.log(chunk)
                        // if ($dayMaxEvents !== false && dayChunks.length > $dayMaxEvents) {
                        // 	chunk.hidden = true;
                        // }
			console.log(chunk.event.title)
			chunk.space = false;
			if (chunk.event.title == "END") {
			    //let chunk2 = Object.assign({}, chunk);
			    //let chunk2 = structuredClone( chunk);
                            let chunk2 =  JSON.parse(JSON.stringify(chunk));
			    chunk2.event.title = "SPACE"
			    chunk2.space = true;
                            dayChunks.push(chunk2);
			}
                        dayChunks.push(chunk);
                    }
                }
		//console.log(chunks.length, dayChunks.length)
                //dayChunks.push({display:false,dumy:true});
            }
        });
    });
    $effect(() => {
        $_hiddenEvents[date.getTime()] = hiddenEvents;
    });

    $effect(() => {
        if (!disabled && $_hiddenEvents && hiddenEvents.size) {
            // make Svelte update this block on $_hiddenEvents update
            let text = "+" + hiddenEvents.size + " more";
            if ($moreLinkContent) {
                moreLink = isFunction($moreLinkContent)
                    ? $moreLinkContent({ num: hiddenEvents.size, text })
                    : $moreLinkContent;
            } else {
                moreLink = text;
            }
        }
    });
    $effect(() => {
        showPopup = $_popupDate && datesEqual(date, $_popupDate);
    });
    $effect(() => {
        if (showPopup && longChunks && dayChunks) {
            // Let chunks to reposition then set popup chunks
            tick().then(setPopupChunks);
        }
    });
    // dateFromPoint
    $effect(() => {
        if (el) {
            setPayload(el, () => ({ allDay: true, date, resource: undefined, dayEl: el, disabled }));
        }
    });
    $effect(() => {
        showWeekNumber = $weekNumbers && date.getUTCDay() == ($firstDay ? 1 : 0);
        if (showWeekNumber) {
            let week = getWeekNumber(date, $firstDay);
            if ($weekNumberContent) {
                weekNumber = isFunction($weekNumberContent)
                    ? $weekNumberContent({ date: toLocalDate(date), week })
                    : $weekNumberContent;
            } else {
                weekNumber = "W" + String(week).padStart(2, "0");
            }
        }
    });
</script>


<style>
      .allDaySlot { height:var(--allDaySlotHeight)}
</style>

<div
    bind:this={el}
    class="{$theme.day} {$theme.weekdays?.[date.getUTCDay()]}{isToday ? ' ' + $theme.today : ''}{otherMonth
        ? ' ' + $theme.otherMonth
        : ''}{highlight ? ' ' + $theme.highlight : ''}{disabled ? ' ' + $theme.disabled : ''}"
    role="cell"
    onpointerdown={$_interaction.action?.select}
    style="--allDaySlotHeight: {allDaySlotHeight}px"
>
    <div class={$theme.dayHead}>
        <time datetime={toISOString(date, 10)} use:setContent={$_intlDayCell.format(date)}></time>
        {#if showWeekNumber}
            <span class={$theme.weekNumber} use:setContent={weekNumber}></span>
        {/if}
    </div>
<!--
    <div class="{$theme.bgEvents} allDaySlot" >
        {#if !disabled}
            {#each dayBgChunks as chunk (chunk.event)}
	        {#if chunk.space }
                    <Event  {chunk} />
                {:else}
		    <div>SPACE</div>
                {/if}
            {/each}
        {/if}
    </div>
-->
    <div class="[{$theme.bgEvents} allDaySlot" >
        {#if !disabled}
            {#each dayBgChunks as chunk, i (chunk.event)}
                <Event {chunk}  {dates} bind:this={refs[i]} />
            {/each}
        {/if}
    </div>

    {#if !disabled}
        <!-- Pointer -->
        {#if iChunks[2] && datesEqual(iChunks[2].date, date)}
            <div class={$theme.events}>
                <Event chunk={iChunks[2]} />
            </div>
        {/if}
        <!-- Drag & Resize -->
        {#if iChunks[0] && datesEqual(iChunks[0].date, date)}
            <div class="{$theme.events} {$theme.preview}">
                <Event chunk={iChunks[0]} />
            </div>
        {/if}
    {/if}
  
    <div class={$theme.events}>
        {#if !disabled}
            {#each dayChunks as chunk, i (chunk.event)}
	    <!--
                <Event {chunk} {longChunks} {dates} bind:this={refs[i]} />
                <Event {chunk} null {dates} bind:this={refs[i]} />
                <Event {chunk} {longChunks} {dates} bind:this={refs[i]} />
	    -->
	        {#if !chunk.space }
                     <Event {chunk} {longChunks} {dates} bind:this={refs[i]} />
                {:else}
		    <EventSpace/>
                {/if}
            {/each}
        {/if}
    </div>
   
    
    {#if showPopup}
        <Popup />
    {/if}
    <div class={$theme.dayFoot}>
        {#if !disabled && hiddenEvents.size}
            <!-- svelte-ignore a11y_missing_attribute -->
            <!-- svelte-ignore a11y_missing_content -->
            <a
                aria-label="GUSA"
                role="button"
                tabindex="0"
                aria-haspopup="true"
                onclick={stopPropagation(showMore)}
                onkeydown={keyEnter(showMore)}
                onpointerdown={stopPropagation(bubble("pointerdown"))}
                use:setContent={moreLink}
            ></a>
        {/if}
    </div>
</div>
