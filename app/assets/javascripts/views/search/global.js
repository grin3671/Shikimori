// import { debounce } from 'throttle-debounce';

import CollectionSearch from './collection';

const ITEM_SELECTOR = '.b-db_entry-variant-list_item';

export default class GlobalSearch extends CollectionSearch {
  initialize() {
    super.initialize();

    this.currentItem = null;
    this._bindGlobalHotkey();

    this.$collection.on('mousemove', ITEM_SELECTOR, ({ currentTarget }) => {
      // better than mouseover cause it does not trigger after keyboard scroll
      if (this.currentItem !== currentTarget) {
        this._selectItem(currentTarget, false);
      }
    });
  }

  get $collection() {
    return this.$root.find('.search-results');
  }

  get $activeItem() {
    return this.$collection.find(`${ITEM_SELECTOR}.active`);
  }

  // handlers
  _onGlobalKeyup(e) {
    if (e.keyCode === 27) {
      this._onGlobalEsc(e);
    } else if (e.keyCode === 47 || e.keyCode === 191) {
      this._onGlobalSlash(e);
    }
  }

  _onGlobalKeydown(e) {
    if (e.keyCode === 40) {
      this._onGlobalDown(e);
    } else if (e.keyCode === 38) {
      this._onGlobalUp(e);
    }
  }

  _onGlobalEsc(e) {
    if (!this.isActive) { return; }

    e.preventDefault();
    e.stopImmediatePropagation();

    this._cancel();
  }

  _onGlobalSlash(e) {
    const target = e.target || e.srcElement;
    const isIgnored = target.isContentEditable ||
      target.tagName === 'INPUT' ||
      target.tagName === 'SELECT' ||
      target.tagName === 'TEXTAREA';

    if (isIgnored) { return; }

    e.preventDefault();
    e.stopImmediatePropagation();

    this.$input.focus();
    this.$input[0].setSelectionRange(0, this.$input[0].value.length);
  }

  _onGlobalDown(e) {
    const { $activeItem } = this;
    const item = $activeItem.length ?
      $activeItem.next()[0] :
      this.$collection.find(ITEM_SELECTOR).first()[0];

    if (this.isActive) {
      e.preventDefault();
      e.stopImmediatePropagation();
    }

    if (item) {
      this._selectItem(item, true);
    }
  }

  _onGlobalUp(e) {
    const { $activeItem } = this;
    const item = $activeItem.prev()[0];

    if (this.isActive) {
      e.preventDefault();
      e.stopImmediatePropagation();
    }

    if (item) {
      this._selectItem(item, true);
    }
  }

  // private functions
  _bindGlobalHotkey() {
    this.globalKeyupHandler = this._onGlobalKeyup.bind(this);
    this.globalKeydownHandler = this._onGlobalKeydown.bind(this);

    $(document).on('keyup', this.globalKeyupHandler);
    $(document).on('keydown', this.globalKeydownHandler);

    $(document).one('turbolinks:before-cache', () => {
      $(document).off('keyup', this.globalKeyupHandler);
      $(document).off('keydown', this.globalKeydownHandler);
    });
  }

  _searchUrl(phrase) {
    return this._url(phrase, 'autocomplete');
  }

  _cancel() {
    if (Object.isEmpty(this.phrase)) {
      this._clearPhrase();
      this.$input.blur();
    } else {
      this._clearPhrase();
    }
    this._deactivate();
  }

  _activate() {
    if (Object.isEmpty(this.phrase)) {
      this._deactivate();
      return;
    }

    this.$collection.show();
    $('.l-top_menu-v2').addClass('is-global_search');

    super._activate();
  }

  _deactivate() {
    this.$collection
      .empty()
      .hide();
    $('.l-top_menu-v2').removeClass('is-global_search');

    this.isActive = false;
  }

  _showAjax() {
    this.$collection.find('.b-nothing_here').remove();
    super._showAjax();
  }

  _selectItem(node, doScroll) {
    this.currentItem = node;

    const $node = $(node);
    $node.siblings().removeClass('active');
    $node.addClass('active');

    if (doScroll) {
      this._scrollToItem($node);
    }
  }

  _scrollToItem($node) {
    let didScroll = false;

    const nodeTop = $node.offset().top;
    const nodeHeight = $node.outerHeight();

    const windowTop = window.scrollY || document.documentElement.scrollTop;
    const windowHeight = $(window).height();

    if (nodeTop < windowTop) {
      didScroll = true;
      if ($node.is(':first-child')) {
        window.scrollTo(0, 0);
      } else {
        window.scrollTo(0, nodeTop - 10);
      }
    } else if (nodeTop + nodeHeight > windowTop + windowHeight) {
      didScroll = true;
      window.scrollTo(0, windowTop + (nodeTop + nodeHeight) - (windowTop + windowHeight) + 10);
    }

    // NOTE: no need in it after switching from mouseover to mousemove
    // to prevent item selection by mouseover event
    // it could happen if mouse cursor currently is over some item
    // if (didScroll) {
    //   document.body.style.pointerEvents = 'none';

    //   if (!this.debouncedEnableMouseEvents) {
    //     this.debouncedEnableMouseEvents = debounce(250, () => (
    //       document.body.style.pointerEvents = ''
    //     ));
    //   }
    //   this.debouncedEnableMouseEvents();
    // }
  }

  _changeUrl(_url) {}
}
