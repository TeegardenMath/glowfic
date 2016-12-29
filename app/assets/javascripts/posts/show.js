/* global resizeScreenname */
$(document).ready(function() {
  // Checks if the user is on the unread page but also started near the unread element,
  // since e.g. on a refresh some browsers will retain your spot on the page
  // Will be used after some page-size-changing functions to revert to the correct spot
  var unreadElem = $("a#unread");
  var shouldScrollToUnread = false;
  if (window.location.hash === "#unread" && unreadElem.length > 0)
    shouldScrollToUnread = Math.abs(unreadElem.offset().top - $(window).scrollTop()) < 50;

  $(".post-expander:not(.post-editor-expander)").click(function() {
    $(this).children(".info").remove();
    $(this).get(0).outerHTML = $(this).children('.hidden').html();
  });

  // Dropdown menu code
  if ($("#post-menu").length > 0) {
    $("#post-menu").click(function() {
      $(this).toggleClass('selected');
      $("#post-menu-box").toggle();
    });

    // Hides selectors when you hit the escape key
    $(document).bind("keydown", function(e) {
      e = e || window.event;
      var charCode = e.which || e.keyCode;
      if (charCode === 27) {
        $('#post-menu-box').hide();
        $('#post-menu').removeClass('selected');
      }
    });

    // Hides selectors when you click outside them
    $(document).click(function(e) {
      var target = e.target;

      if (!$(target).is('#post-menu-box') && !$(target).parents().is('#post-menu-box')
        && !$(target).is('#post-menu') && !$(target).parents().is('#post-menu')) {
        $('#post-menu-box').hide();
        $('#post-menu').removeClass('selected');
      }
    });
  }

  // Make expanders work in NoScript
  $('.post-expander').each(function() {
    // set up expander post noscript
    var expander = $(this);
    var expanderText = expander.data('expander-text');
    var infoBox = $("<div class='info'>").append(expanderText);
    var hiddenBox = $("<div class='hidden'>").append(expander.children(":not(.noexpand)"));
    hiddenBox.append(hiddenBox.children('.hidden.expand').children());
    hiddenBox.children('.hidden.expand').remove();
    expander.children('.noexpand').remove();
    expander.append(infoBox).append(hiddenBox);
  });

  // TODO fix hack
  // Resizes screennames to be slightly smaller if they're long for UI reasons
  $(".post-screenname").each(function() {
    resizeScreenname(this);
  });

  // Now that we've finished the scripts that change page locations, scroll to #unread
  // if we determined on page load that we should.
  if (shouldScrollToUnread)
    $(window).scrollTop(unreadElem.offset().top);
});
