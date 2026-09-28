(function ($) {

    'use strict';

    /**
     * FAQ's setup
     *
     * Remove .nojs from .qe-faq-toggle elements, and collapse all expanded
     * elements
     */
    var all_toggles = $('.qe-faq-toggle');

    all_toggles.removeClass('nojs active');
    all_toggles.find('i.fa').removeClass('fa-minus-circle').addClass('fa-plus-circle');

    /**
     * FAQs Toggles
     */
    $('.qe-toggle-title').click(function () {

        var parent_toggle = $(this).closest('.qe-faq-toggle');

        if('accordion' === qaef_object.style || 'accordion-grouped' === qaef_object.style ){
            parent_toggle.siblings().removeClass('active').find('.qe-toggle-content').slideUp('fast');
            parent_toggle.siblings().find('i.fa').removeClass('fa-minus-circle').addClass('fa-plus-circle');
        }
        if (parent_toggle.hasClass('active')) {

            $(this).find('i.fa').removeClass('fa-minus-circle').addClass('fa-plus-circle');
            parent_toggle.removeClass('active').find('.qe-toggle-content').slideUp('fast');
        } else {

            $(this).find('i.fa').removeClass('fa-plus-circle').addClass('fa-minus-circle');
            parent_toggle.addClass('active').find('.qe-toggle-content').slideDown('fast');
        }
    });

    /**
     * FAQs Filter
     */
    $('.qe-faqs-filter').click(function (event) {

        event.preventDefault();

        $(this).parents('li').addClass('active').siblings().removeClass('active');

        var filterSelector = $(this).attr('data-filter'),
            allFAQs = $(this).closest('.qae-faqs-container').find('.qe-faq-toggle, .qe-faq-list, ol.qe-faqs-index-list li');

        if (filterSelector === '*') {
            allFAQs.show();
        } else {
            allFAQs.not(filterSelector).hide().end().filter(filterSelector).show();
        }
    });

})(jQuery);
