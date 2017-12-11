/**
 * ready method
 */
$(document).ready(function() {
    categoryDisplay();
});

/**
 * display category
 * when clicking category on the right
 * relevant posts expand on the left
 * @return {[type]} [description]
 */
function categoryDisplay() {
    selectCategory();
    $('.categories-item').click(function() {
        window.location.hash = "#" + $(this).attr("cate");
        selectCategory();
    });
}

function selectCategory(){
    var exclude = ["",undefined];
    var thisId = window.location.hash.substring(1);
    var allow = true;
    for(var i in exclude){
        if(thisId == exclude[i]){
            allow = false;
            break;
        }
    }
    if(allow){
        var cate = thisId;
        $("section[post-cate!='" + cate + "']").hide(200);
        $("section[post-cate='" + cate + "']").show(200);
    } else {
        $("section[post-cate='All']").show();
    }
}