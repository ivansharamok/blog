---
    layout: null
---

/**
 * ready method
 */
$(document).ready(function() {

    console.log("Loading document");

    backToTop();
});

/**
 * back to the top function
 */
function backToTop() {
    $("[data-toggle='tooltip']").tooltip();
    var st = $(".page-scrollTop");
    var $window = $(window);
    var topOffset;
    // scroll doesn't appear unless at the top
    $window.scroll(function() {
        var currnetTopOffset = $window.scrollTop();
        if (currnetTopOffset > 0 && topOffset > currnetTopOffset) {
            st.fadeIn(500);
        } else {
            st.fadeOut(500);
        }
        topOffset = currnetTopOffset;
    });

    // click back to top
    st.click(function() {
        $("body").animate({
            scrollTop: "0"
        }, 500);
    });


}




