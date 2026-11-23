// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtTest

import LocalTranslate

// Checks the grouping rules of the language dropdown: pinned first, then
// recently used, then everything else, with each language listed exactly once.
TestCase {
    id: testCase
    name: "LanguageSelector"

    // Some tests open the popup and inspect real delegates, which needs a
    // shown window.
    when: windowShown

    readonly property var languages: [
        { code: "ar", name: "Arabic" },
        { code: "de", name: "German" },
        { code: "en", name: "English" },
        { code: "es", name: "Spanish" },
        { code: "fr", name: "French" },
        { code: "hu", name: "Hungarian" },
        { code: "ja", name: "Japanese" },
        { code: "pt", name: "Portuguese" }
    ]

    Component {
        id: selectorComponent

        LanguageSelector {
            allLanguages: testCase.languages
        }
    }

    function createSelector(pinned, recent, selected) {
        const selector = createTemporaryObject(selectorComponent, testCase, {
            pinnedCodes: pinned,
            recentCodes: recent
        })
        verify(selector, "selector was created")
        selector.selectByCode(selected)
        return selector
    }

    // The codes of the language rows, in display order, ignoring the
    // "All other" disclosure row.
    function languageCodes(selector) {
        return selector.rows.filter(row => row.kind === "lang")
                            .map(row => row.lang.code)
    }

    function test_plain_list_without_pins_or_recents() {
        const selector = createSelector([], [], "en")

        verify(!selector.grouped, "no grouping without pins or recents")
        compare(languageCodes(selector).length, languages.length)
        compare(selector.rows.filter(row => row.kind === "toggle").length, 0,
                "no disclosure row when the list is not grouped")
    }

    function test_pinned_languages_come_first() {
        const selector = createSelector(["hu", "de"], [], "en")

        // Pinned entries keep the alphabetical order of the full list.
        compare(selector.pinnedLanguages.map(lang => lang.code), ["de", "hu"])
        compare(languageCodes(selector).slice(0, 2), ["de", "hu"])
    }

    function test_recents_follow_pinned() {
        const selector = createSelector(["de"], ["fr", "es"], "en")
        selector.otherExpanded = true

        compare(selector.recentLanguages.map(lang => lang.code), ["fr", "es"])
        compare(languageCodes(selector).slice(0, 3), ["de", "fr", "es"])
    }

    function test_pinned_language_is_not_repeated_in_recents() {
        const selector = createSelector(["de"], ["de", "fr"], "en")

        compare(selector.recentLanguages.map(lang => lang.code), ["fr"],
                "a pinned language does not also occupy a recents slot")
    }

    function test_current_language_is_not_listed_as_recent() {
        const selector = createSelector([], ["fr", "es"], "fr")

        compare(selector.recentLanguages.map(lang => lang.code), ["es"],
                "the current language is already visible on the closed control")
    }

    function test_recents_are_capped() {
        const selector = createSelector([], ["ar", "es", "fr", "ja", "pt"], "en")

        compare(selector.recentLanguages.length, selector.maxRecent)
        compare(selector.recentLanguages.map(lang => lang.code), ["ar", "es", "fr"],
                "the most recent entries win")
    }

    function test_unknown_codes_are_ignored() {
        const selector = createSelector(["zz"], ["qq", "fr"], "en")

        compare(selector.recentLanguages.map(lang => lang.code), ["fr"],
                "codes with no matching language are dropped")

        // The bogus pin is dropped too, so only the recent language is lifted
        // out of the collapsed group.
        compare(languageCodes(selector), ["fr"])
        selector.otherExpanded = true
        compare(languageCodes(selector).length, languages.length,
                "every real language is still reachable")
    }

    function test_every_language_is_listed_exactly_once() {
        const cases = [
            { pinned: [], recent: [], selected: "en" },
            { pinned: ["de", "hu"], recent: [], selected: "en" },
            { pinned: [], recent: ["fr", "es"], selected: "en" },
            { pinned: ["de", "hu"], recent: ["fr", "es"], selected: "en" },
            { pinned: ["de"], recent: ["de", "fr"], selected: "fr" }
        ]

        for (const testData of cases) {
            const selector = createSelector(testData.pinned, testData.recent,
                                            testData.selected)
            selector.otherExpanded = true

            const codes = languageCodes(selector)
            const label = JSON.stringify(testData)
            compare(codes.length, languages.length, "all languages listed: " + label)
            compare(new Set(codes).size, codes.length, "no duplicates: " + label)
        }
    }

    function test_collapsed_group_hides_the_remaining_languages() {
        const selector = createSelector(["de", "hu"], [], "de")

        verify(selector.grouped, "pins introduce grouping")
        verify(!selector.showOther, "the rest of the list starts collapsed")
        compare(languageCodes(selector), ["de", "hu"])

        selector.toggleOther()
        verify(selector.showOther, "the disclosure row expands the group")
        compare(languageCodes(selector).length, languages.length)
    }

    // The group used to auto-expand whenever it held the selection. That made
    // the popup taller than the window on open, which left the style no room
    // to drop it below the control, so it was centred over the app header
    // instead. Searching replaces that convenience.
    function test_group_stays_collapsed_even_when_it_holds_the_selection() {
        // Portuguese is neither pinned nor recent, so it lives in "All other".
        const selector = createSelector(["de", "hu"], [], "pt")

        verify(!selector.showOther,
               "the group stays collapsed so the popup stays short")
        compare(languageCodes(selector), ["de", "hu"],
                "only the pinned languages are listed")
    }

    function test_each_popup_starts_collapsed_again() {
        const selector = createSelector(["de", "hu"], [], "de")
        selector.toggleOther()
        verify(selector.showOther, "expanded by hand")

        selector.popup.open()
        tryVerify(() => selector.popup.opened)
        verify(!selector.showOther, "opening the popup collapses the group again")
        selector.popup.close()
    }

    // Typing narrows the whole list, which is what makes a collapsed "All
    // other" group acceptable: an unlisted language is found by searching
    // rather than by expanding and scrolling.
    function test_search_matches_on_name_and_code() {
        const selector = createSelector(["hu"], ["fr"], "en")

        selector.filter = "ger"
        verify(selector.searching)
        compare(languageCodes(selector), ["de"], "matched on the name")

        selector.filter = "de"
        compare(languageCodes(selector), ["de"], "matched on the code")

        // Matching anywhere in the name, not just at the start.
        selector.filter = "nese"
        compare(languageCodes(selector), ["ja"])

        // Case is irrelevant.
        selector.filter = "SPAN"
        compare(languageCodes(selector), ["es"])

        selector.filter = "zzz"
        compare(languageCodes(selector), [], "no matches is an empty list")
    }

    // While searching, the groups are set aside: pinned and recent are ways of
    // not having to search, so they only get in the way of reading results.
    function test_search_replaces_the_grouping() {
        const selector = createSelector(["hu"], ["fr"], "en")

        selector.filter = "a"
        compare(selector.rows.filter(row => row.kind === "toggle").length, 0,
                "no disclosure row while searching")
        verify(selector.rows.every(row => row.group === "match"),
               "every result is tagged as a match")

        // Clearing the query restores the collapsed grouping.
        selector.filter = ""
        verify(!selector.searching)
        verify(!selector.showOther, "the group is collapsed again")
        verify(selector.rows.some(row => row.kind === "toggle"),
               "the disclosure row is back")
    }

    // Searching shows results whether or not the group was expanded, so a
    // match in "All other" is reachable without expanding anything.
    function test_search_finds_languages_inside_the_collapsed_group() {
        const selector = createSelector(["hu"], ["fr"], "en")
        verify(!selector.showOther, "Portuguese is hidden in the collapsed group")
        compare(languageCodes(selector).indexOf("pt"), -1)

        selector.filter = "port"
        compare(languageCodes(selector), ["pt"], "and is still found by typing")
    }

    // Real keystrokes, which is the path the Keys handler actually sees: the
    // property-level tests above cannot catch a control that never receives
    // the keys, or one whose label does not show what was typed.
    function test_typing_filters_the_list() {
        const selector = createSelector(["hu"], ["fr"], "en")
        compare(selector.displayText, "English", "the selection shows when idle")

        selector.popup.open()
        tryVerify(() => selector.popup.opened)
        verify(selector.activeFocus, "opening the popup focuses the control")

        keyClick(Qt.Key_G, Qt.NoModifier, 50, selector)
        compare(selector.filter, "g", "the keystroke reaches the filter")
        compare(selector.displayText, "g", "and the control shows the query")

        keyClick(Qt.Key_E, Qt.NoModifier, 50, selector)
        keyClick(Qt.Key_R, Qt.NoModifier, 50, selector)
        compare(selector.filter, "ger")
        compare(languageCodes(selector), ["de"], "only German is left")

        keyClick(Qt.Key_Backspace, Qt.NoModifier, 50, selector)
        compare(selector.filter, "ge", "backspace widens the query")

        selector.popup.close()
        tryVerify(() => !selector.popup.opened)
        compare(selector.filter, "", "closing clears the search")
        compare(selector.displayText, "English",
                "the label shows the selection again, not the query")
    }

    // Escape is a two-step: clear the query, then close. Closing on the first
    // press would throw away the search on a typo.
    function test_escape_clears_the_query_before_closing() {
        const selector = createSelector(["hu"], ["fr"], "en")
        selector.popup.open()
        tryVerify(() => selector.popup.opened)

        keyClick(Qt.Key_G, Qt.NoModifier, 50, selector)
        compare(selector.filter, "g")

        keyClick(Qt.Key_Escape, Qt.NoModifier, 50, selector)
        compare(selector.filter, "", "the query is cleared")
        verify(selector.popup.opened, "and the popup is still open")
        verify(!selector.showOther, "with the collapsed grouping back")

        selector.popup.close()
        tryVerify(() => !selector.popup.opened)
    }

    // A search result is picked with Return like any other row.
    function test_search_result_can_be_selected() {
        const selector = createSelector(["hu"], ["fr"], "en")
        selector.popup.open()
        tryVerify(() => selector.popup.opened)

        keyClick(Qt.Key_J, Qt.NoModifier, 50, selector)
        compare(languageCodes(selector), ["ja"])

        let picked = ""
        selector.languageSelected.connect(code => picked = code)
        keyClick(Qt.Key_Return, Qt.NoModifier, 50, selector)
        tryVerify(() => !selector.popup.opened)

        compare(picked, "ja", "return picks the match")
        compare(selector.selectedCode, "ja")
        compare(selector.displayText, "Japanese", "and the query is gone")
    }

    // The delegate cannot reach the enclosing component when the QML is
    // loaded from compiled resources, so everything it draws has to come from
    // the row it is handed. These tests open the popup and inspect the real
    // delegate instances, which plain property checks would not catch.
    // Opens the popup and drives a real delegate. The delegate cannot reach
    // the enclosing component when the QML is loaded from compiled resources,
    // so this covers the wiring that plain property checks miss.
    function test_pin_button_reports_the_language_to_pin() {
        const selector = createSelector(["hu"], ["fr"], "en")
        let pinned = ""
        selector.pinToggled.connect(code => pinned = code)

        selector.popup.open()
        tryVerify(() => selector.popup.contentItem.count === selector.rows.length)

        const row = selector.popup.contentItem.itemAtIndex(0)
        verify(row, "the delegate was instantiated")
        verify(row.width > 0, "the delegate knows how wide to be")
        compare(row.modelData.name, selector.rows[0].name,
                "the row draws from its own data")

        row.contentItem.children[1].clicked()
        compare(pinned, selector.rows[0].code,
                "the pin button reports the language on its own row")
        selector.popup.close()
    }

    // Every row carries the group it belongs to, which is what lets the
    // delegate fade the recent rows without reaching outside itself.
    function test_rows_carry_their_group() {
        const selector = createSelector(["hu"], ["fr", "de"], "en")
        selector.otherExpanded = true

        const groupOf = code => selector.rows.find(
                                    row => row.code === code).group
        compare(groupOf("hu"), "pinned", "pins are tagged as pinned")
        compare(groupOf("fr"), "recent", "recents are tagged as recent")
        compare(groupOf("de"), "recent")
        compare(groupOf("ja"), "other", "the rest are tagged as other")
        compare(selector.rows.find(row => row.kind === "toggle").group, "toggle")
    }

    // The disclosure row is a control, not a choice: clicking it has to expand
    // the group in place rather than pick a language and dismiss the popup.
    function test_disclosure_row_expands_without_closing_the_popup() {
        const selector = createSelector(["hu"], [], "hu")
        verify(!selector.showOther, "the rest of the list starts collapsed")

        selector.popup.open()
        tryVerify(() => selector.popup.opened)
        tryVerify(() => selector.popup.contentItem.count === selector.rows.length)

        const toggleIndex = selector.rows.findIndex(row => row.kind === "toggle")
        const row = selector.popup.contentItem.itemAtIndex(toggleIndex)
        verify(row, "the disclosure row was instantiated")

        row.clicked()
        verify(selector.showOther, "clicking the row expands the group")
        verify(selector.popup.opened, "the popup stays open")
        compare(selector.selectedCode, "hu", "the selection is untouched")

        selector.popup.close()
    }

    function test_selection_survives_the_list_being_regrouped() {
        const selector = createSelector([], [], "fr")
        compare(selector.selectedCode, "fr")

        // Pinning reorders the model; the selection must follow the language
        // rather than stay on a row index.
        selector.pinnedCodes = ["ja", "pt"]
        compare(selector.selectedCode, "fr")
        compare(selector.currentLanguage.code, "fr")
        compare(selector.displayText, "French")
    }
}
