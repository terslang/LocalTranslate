// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtTest

import LocalTranslate

// Checks the grouping rules of the language dropdown: pinned first, then
// recently used, then everything else, with each language listed exactly once.
TestCase {
    id: testCase
    name: "LanguageSelector"

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
        selector.otherExpansion = "expanded"

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
        compare(languageCodes(selector).length, languages.length)
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
            selector.otherExpansion = "expanded"

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

    function test_group_opens_when_it_holds_the_selection() {
        // Portuguese is neither pinned nor recent, so it lives in "All other".
        const selector = createSelector(["de", "hu"], [], "pt")

        verify(selector.otherHoldsSelection)
        verify(selector.showOther, "the selection is never hidden in a collapsed group")

        // The user can still collapse it from there.
        selector.toggleOther()
        verify(!selector.showOther, "an explicit collapse wins over auto-expansion")
    }

    function test_expansion_returns_to_automatic_once_the_selection_moves_out() {
        const selector = createSelector(["de", "hu"], [], "pt")
        selector.toggleOther()
        verify(!selector.showOther)

        selector.selectByCode("de")
        compare(selector.otherExpansion, "auto",
                "the next popup starts collapsed again")
        verify(!selector.showOther)
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
