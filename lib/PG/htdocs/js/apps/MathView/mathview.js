// Class constructor
// Create the equation editor decorator around the decoratedTextBox and
// generate PGML or LaTeX code depending ont the renderingMode option.
// params:
//    decoratedTextBox: the text box being decorated this is now always defined using the
//                      class constructor
//    rederingMode: Either "PGML" to render PGML code or "LATEX" to render LaTeX code.

// Note: This version has been forked from the 1.1.0 mathveiw release and is now WeBWorK specific

/* load up and config mathview */
window.addEventListener('DOMContentLoaded', function () {
	/* Makes escape key hide any visible popups */
	document.addEventListener('keydown', (e) => {
		if (e.key === 'Escape')
			document.querySelectorAll('.popover').forEach((popover) => {
				bootstrap.Popover.getInstance(popover).hide();
			});
	});

	/* attach a viewer to each answer input */
	document.querySelectorAll('.codeshard').forEach(input => {
		/* create button and attach it to side of input */
		$(input).wrap('<div class="input-group d-inline-flex flex-nowrap w-auto">');

		/* define the button and place it */
		var button = $('<a>', {
			href: '#',
			class: 'btn btn-sm btn-secondary codeshard-btn',
		}).append($('<span>', {'data-alt': 'Equation Editor'})
			.append($('<i>', {class: 'fas fa-th'}))
			.append($('<div>', {class: 'sr-only-glyphicon'}).html('equation editor')));
		$(input).parent().append(button);

		/* generate the mathviewer */
		var mviewer = new MathViewer(input, button, $(input).parent('.input-group'));
		mviewer.initialize();

		/* set mviewer behavior specific to problem inputs */
		/* have button close other open mviewers */
		mviewer.button.on('click', function () {
			var current = this;

			$('.codeshard').each(function () {
				var others = $(this).siblings('a')[0];
				if (others != current) {
					$(others).popover('hide');
				}
			});
		});

		/* have the mviewer close if the input loses focus */
		$(input).on('focus', function () {
			var current = $(this).siblings('a')[0];

			$('.codeshard').each(function () {
				var others = $(this).siblings('a')[0];
				if (others != current) {
					$(others).popover('hide');
				}
			});
		});

	});

	/* attach an editor to any needed latex/pg fields */
	$('.latexentryfield').each(function () {
		var input = this;

		/* define the button and place it */
		var button = $('<a>', {href: '#', class: 'btn', style: 'margin-left : 2ex; vertical-align : top'})
			.html('<span class="icon icon-pencil" data-alt="Equation Editor"></span>')
		$(input).after(button);
		options = {
			renderingMode: 'LATEX',
			decoratedTextBoxAsInput: false,
			autocomplete: false,
			includeDelimiters: true
		};

		/* generate the mathviewer */
		var mviewer = new MathViewer(input, button, 'body', options);
		mviewer.initialize();

	});

	function MathViewer(field, button, container, userOptions) {
		var defaults = {
			renderingMode: "PGML",
			decoratedTextBoxAsInput: true,
			autocomplete: true,
			includeDelimiters: false
		}

		this.options = $.extend({}, defaults, userOptions);

		this.renderingMode = this.options.renderingMode;

		/* give a unique index to this instance of the viewer */
		if (typeof MathViewer.viewerCount == 'undefined') {
			MathViewer.viewerCount = 0;
		}
		MathViewer.viewerCount++;
		var viewerIndex = MathViewer.viewerCount;
		var me = this;
		this.decoratedTextBox = $(field);
		this.button = $(button);

		if (this.options.decoratedTextBoxAsInput) {
			this.inputTextBox = $(field);
		} else {
			this.inputTextBox = $('<input>', {type: 'text', class: 'mv-input', size: '32'});
		}

		/* start setting up html elements */
		var popupdiv;
		var popupttl;
		var dropdown;
		var tabContent;

		/* make sure the popover opens when we click the button */
		this.button.on('click', function () {
			me.button.popover('toggle');
			me.inputTextBox.trigger('keyup');
			MathJax.startup.promise = MathJax.startup.promise.then(() => MathJax.typesetPromise(['.popover']));
			return false;
		});


		/* set mviewer behavior specific to problem inputs */

		/* initialization function does heavy lifting of generating html */
		this.initialize = function () {

			/* start setting up html elements */
			popupdiv = $('<div>', {class: 'popupdiv'});
			popupttl = $('<div>', {class: 'navbar', role: 'menubar'});
			dropdown = $('<ul>', {class: 'dropdown-menu', role: 'menu'});
			tabContent = $('<div>', {class: 'tab-content'});

			/* generate html for each of the categories in the locale file */
			$.each(mv_categories, this.createCat);

			/* create the title bar with dropdown menue and move/close buttons */
			popupttl.append($('<div>', {class: 'container-fluid p-0'})
				.append($('<ul>', {class: 'nav'})
					.append($('<div class="navbar-brand">' + mathView_translator[7] /*Equation Editor*/ + '</div>'))
					.append($('<li>', {class: 'nav-item dropdown'})
						.append($('<button>', {
							type: 'button',
							id: `menu${viewerIndex}`,
							class: 'btn btn-secondary dropdown-toggle',
							'data-bs-toggle': 'dropdown',
							'aria-expanded': false
						}).text('Operations'))
						.append(dropdown)))
				.append($('<button>', {class: 'btn-close', 'aria-label': 'Close'})
					.on('click', function () {
						me.button.popover('hide');
						return false;
					})));

			// put the categories content into the main popop div, activate the tabs, and put the preview div in place

			popupdiv.append(tabContent);

			dropdown.find('a:first').tab('show');
			tabContent.find('.tab-pane:first').addClass('active');

			popupdiv.append($('<div>', {class: 'card bg-light p-2 overflow-auto'})
				.append($('<div>', {
					id: `mviewer${viewerIndex}`,
					class: 'mviewer d-flex justify-content-center align-items-center'
				})));

			if (!this.options.decoratedTextBoxAsInput) {
				var insertbutton = $('<a>', {href: '#', class: 'btn btn-primary'}).html('Insert');
				popupdiv.append($('<div>', {class: 'mvinput'}).append(this.inputTextBox).append(insertbutton));
				insertbutton.on('click', function () {
					var insertstring = me.inputTextBox.val();
					if (me.options.includeDelimiters) {
						insertstring = '\\(' + insertstring + '\\)';
					}
					me.decoratedTextBox.insertAtCaret(insertstring);
					return false;
				});
			}

			$('#mviewer' + viewerIndex).html(me.inputTextBox.val());

			this.regenPreview();

			/* set up the autocomplete feature */
			//if (this.options.autocomplete) {
			//	this.createAutocomplete();
			//}

			/* make sure popover refreshes math when there is a keyup in the input */
			$(this.inputTextBox).on('keyup', this.regenPreview);

			/* actually initialize the popover */
			this.button.popover({
				html: true,
				content: this.popoverContent,
				trigger: 'manual',
				placement: 'right',
				title: this.popoverTitle,
				container: container
			});
			$(container).addClass('mv-container');

		}

		/* This function inserts the appropriate string into the
	   input box when a button in the viewer is pressed */

		this.generateTex = function (strucValue) {
			var pos = me.inputTextBox.getCaretPos();
			var newpos = pos;

			if (me.renderingMode == "LATEX") {
				me.inputTextBox.insertAtCaret(strucValue.latex);
				var parmatch = strucValue.latex.match(/\(\)|\[,|\(,/);
				if (parmatch) {
					newpos += parmatch[0].index;
				}
				me.inputTextBox.setCaretPos(newpos);
				me.inputTextBox.trigger('keyup');
			} else if (me.renderingMode == "PGML") {
				me.inputTextBox.insertAtCaret(strucValue.PG);
				var parmatch = strucValue.PG.match(/\(\)|\[,|\(,/);
				if (parmatch) {
					newpos += parmatch.index + 1;
				}
				me.inputTextBox.setCaretPos(newpos);
				me.inputTextBox.trigger('keyup');
			} else
				console.log('Invalid Rendering Mode');
		}

		/* this function regenerates the preview in the math viewer
	   whenever the input value changes */

		this.regenPreview = function () {
			var text = me.inputTextBox.val().replace(/\*\*/g, '^');

			/* This escapes any html in the input field, preventing xss */
			text = $('<div>').text(text).html();

			var mviewer = $('#mviewer' + viewerIndex);
			if (!mviewer.length) return;
			if (me.renderingMode == "LATEX") {
				mviewer.html("<div>\\(" + text + "\\)</div>");
				MathJax.startup.promise = MathJax.startup.promise.then(() => MathJax.typesetPromise([mviewer[0]]));
			} else if (me.renderingMode == "PGML") {
				mviewer.html("<div>`" + text + "`</div>");
				MathJax.startup.promise = MathJax.startup.promise.then(() => MathJax.typesetPromise([mviewer[0]]));
			} else
				console.log('Invalid Rendering Mode');
		};

		/* this function returns the html for the body of the math viewer */

		this.popoverContent = function () {
			me.initialize();
			return popupdiv;

		};

		/* this function returns the html for the title of the math viewer */

		this.popoverTitle = function () {
			return popupttl;
		};

		/* this function creates a category from the locale js.
	   each category is implemented using bootstraps tab feature.
	   The selectors for the tab go in a dropdown menu.  The tabs contain
	   a thumbnail grid of the buttons in the category
	   */

		this.createCat = function (catCount, catValue) {
			var thisTabList = $('<ul>', {
				class: 'mvthumbnails d-flex flex-wrap justify-content-evenly m-0 p-0 list-unstyled'
			});

			$.each(catValue.operators, function (i, value) {

				var className = 'opImg' + catCount + i;
				/* creates a li for each operator/button in the category */
				thisTabList.append($('<li>', {class: 'mvspan3 mx-2 mb-4'})
					.append($('<a>', {
						href: '#',
						class: 'mvthumbnail text-center',
						'aria-controls': '#' + me.decoratedTextBox.attr('id'),
					})
						.on('click', function (event) {
							event.preventDefault();
						})
						.append(value.text)
						.append($('<div/>', {class: 'sr-only-glyphicon'}).html(value.tooltip))
						.tooltip({
							trigger: 'hover',
							delay: {show: 500, hide: 100},
							title: value.tooltip
						})
						.addClass(className).click(function () {
							me.generateTex(value);
						})));
			});

			/* create acutal tab pane for category and add entry to list*/
			tabContent.append($('<div>', {
				class: 'tab-pane',
				id: 'mvtab' + viewerIndex + catCount
			})
				.append(thisTabList));

			dropdown.append($('<li>')
				.append($('<a>', {
					href: '#mvtab' + viewerIndex + catCount,
					class: 'dropdown-item',
					'data-bs-toggle': 'tab',
					'role': 'menuitem',
				})
					.append(catValue.text)
					.on('click', function () {
						$('#menu' + viewerIndex).trigger('focus');
					})));
		};

		/* enables an autocomplete feature for the input */
		// FIXME:  Bootstrap no longer has typeahead.  So this needs to be replaced with something else.
		//this.createAutocomplete = function () {
		//	var source = [];

		//	/* get autocomplete functions and put into list */
		//	$.each(mv_categories, function (_cati, catval) {
		//		$.each(catval.operators, function (_i, val) {
		//			if (val.autocomp) {
		//				source.push(val.PG);
		//			}
		//		});
		//	});


		//	/* implement autocomplete feature using bootstrap typeahead */
		//	$(me.inputTextBox).attr('autocomplete', 'off')
		//		.typeahead({
		//			source: source,
		//			minLength: 0,
		//			/* the matcher function tries to strip off all of the parts
		//		   of the equation before and after the cursor position that
		//		   are not a-z and compares to item */
		//			matcher: function (item) {
		//				var len = this.query.length;
		//				var pos = me.inputTextBox.getCaretPos();
		//				var re = new RegExp('[a-z]*.{' + (len - pos) + '}$');
		//				var query = this.query;
		//				var match = query.match(re);
		//				if (!match)
		//					return false;
		//				query = match[0];
		//				re = new RegExp('^.{' + (pos - (len - query.length)) + '}[a-z]*');
		//				match = query.match(re);
		//				if (!match)
		//					return false;
		//				query = match[0];
		//				if (query.length < 1)
		//					return false;
		//				re = new RegExp('^' + query);
		//				item = item.replace(/\(\)/, '');

		//				/* dont display popup if we are done typing function */
		//				if (item == query + '(') {
		//					return false;
		//				}

		//				match = item.match(re);
		//				if (match) {
		//					return true;
		//				}
		//				return false;
		//			},
		//			/* this function actually generates the new string
		//		   to be put into the input.  It inserts the full function
		//		   at the cursor position */
		//			updater: function (item) {
		//				var len = this.query.length;
		//				var pos = me.inputTextBox.getCaretPos();
		//				var newpos = pos;
		//				var re = new RegExp('[a-z]*.{' + (len - pos) + '}$');
		//				var query = this.query;
		//				var query = query.match(re)[0];
		//				re = new RegExp('^.{' + (pos - (len - query.length)) + '}[a-z]*');
		//				query = query.match(re)[0];
		//				var parmatch = item.match(/\(\)|\[,|\(,/);
		//				if (parmatch) {
		//					newpos += parmatch.index + 1;
		//				} else {
		//					newpos += item.length;
		//				}
		//				newpos -= query.length;
		//				item = item.replace(query, '');
		//				me.inputTextBox.change(function () {
		//					me.inputTextBox.setCaretPos(newpos);
		//					me.inputTextBox.off('change');
		//				});

		//				return [this.query.slice(0, pos),
		//					item,
		//					this.query.slice(pos)].join('');
		//			}
		//		});

		//	/* this overrides a broken part of bootstrap */
		//	$(me.inputTextBox).data('typeahead').move = function (e) {
		//		if (!this.shown) return;

		//		if (e.type === 'keypress') return; //40 and 38 are characters in a keypress

		//		switch (e.keyCode) {
		//			case 9: // tab
		//			case 13: // enter
		//			case 27: // escape
		//				e.preventDefault()
		//				break

		//			case 38: // up arrow
		//				e.preventDefault()
		//				this.prev()
		//				break

		//			case 40: // down arrow
		//				e.preventDefault()
		//				this.next()
		//				break
		//		}
		//		e.stopPropagation();

		//	}
		//};
	}

	/* this is a function I found on the internet to insert text at a the cursor
	   position in a text box */

	$.fn.insertAtCaret = function (myValue) {
		return this
			.each(function () {
				var me = this;
				if (document.selection) { // Internet Explorer
					me.focus();
					sel = document.selection.createRange();
					sel.text = myValue;
					me.focus();
				} else if (me.selectionStart || me.selectionStart == '0') { // Others browsers
					var startPos = me.selectionStart;
					endPos = me.selectionEnd;
					var scrollTop = me.scrollTop;
					me.value = me.value.substring(0, startPos) + myValue
						+ me.value.substring(endPos, me.value.length);
					me.focus();
					me.selectionStart = startPos + myValue.length;
					me.selectionEnd = startPos + myValue.length;
					me.scrollTop = scrollTop;
				} else {
					me.value += myValue;
					me.focus();
				}
			});
	};

	/* this is a function I found on the internet to find the position of a cursor
	   in the text box */

	$.fn.getCaretPos = function () {
		var input = this.get(0);
		if (!input) return; // No (input) element found
		if ('selectionStart' in input) {
			// Standard-compliant browsers
			return input.selectionStart;
		} else if (document.selection) {
			// IE
			input.focus();
			var sel = document.selection.createRange();
			var selLen = document.selection.createRange().text.length;
			sel.moveStart('character', -input.value.length);
			return sel.text.length - selLen;
		}
	};

	/* this is a function i found on the enternet to set the position of a cursor
	   in the text box */

	$.fn.setCaretPos = function (pos) {
		var obj = this.get(0);

		//FOR IE
		if (obj.setSelectionRange) {
			obj.focus();
			obj.setSelectionRange(pos, pos);
		}

		// For Firefox
		else if (obj.createTextRange) {
			var range = obj.createTextRange();
			range.collapse(true);
			range.moveEnd('character', pos);
			range.moveStart('character', pos);
			range.select();
		}
	}

});
