import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';
import Component from '@ember/component';
import bootbox from "bootbox";

export default Component.extend({
  didInsertElement() {
    console.log(this.category);
  },
  
  actions: {
    clearAll() {
      bootbox.confirm(
        I18n.t("composer_template.clear_all.description"),
        I18n.t("no_value"),
        I18n.t("yes_value"),
        (clearAll) => {
          if (!clearAll) {
            return;
          }

          ajax(`/rstudio-composer-template/clear-all/${this.category.id}`, {
            type: 'POST'
          }).catch(popupAjaxError);
        }
      );
    }
  }
});