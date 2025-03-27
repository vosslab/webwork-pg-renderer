'use strict';

/* global MathQuill, bootstrap */

(() => {
	// Global list of all MathQuill answer inputs.
	window.answerQuills = {};

	// initialize MathQuill
	const MQ = MathQuill.getInterface(2);

	const setupMQInput = (mq_input) => {
		const answerLabel = mq_input.id.replace(/^MaThQuIlL_/, '');
		const input = document.getElementById(answerLabel);
		const inputType = input?.type;
		if (typeof(inputType) != 'string'
			|| inputType.toLowerCase() !== 'text'
			|| !input.classList.contains('codeshard'))
			return;

		const answerQuill = document.createElement('span');
		answerQuill.id = `mq-answer-${answerLabel}`;
		answerQuill.input = input;
		input.classList.add('mq-edit');
		answerQuill.latexInput = mq_input;

		input.after(answerQuill);

		// Default options.
		const cfgOptions = {
			spaceBehavesLikeTab: true,
			leftRightIntoCmdGoes: 'up',
			restrictMismatchedBrackets: true,
			sumStartsWithNEquals: true,
			supSubsRequireOperand: true,
			autoCommands: 'pi sqrt root vert inf union abs',
			rootsAreExponents: true,
			maxDepth: 10
		};

		// Merge options that are set by the problem.
		if (answerQuill.latexInput.dataset.mqOpts)
			Object.assign(cfgOptions, JSON.parse(answerQuill.latexInput.dataset.mqOpts));

		// This is after the option merge to prevent handlers from being overridden.
		cfgOptions.handlers = {
			edit: (mq) => {
				if (mq.text() !== '') {
					answerQuill.input.value = mq.text().trim();
					answerQuill.latexInput.value = mq.latex().replace(/^(?:\\\s)*(.*?)(?:\\\s)*$/, '$1');
				} else {
					answerQuill.input.value = '';
					answerQuill.latexInput.value = '';
				}
			},
			// Disable the toolbar when a text block is entered.
			textBlockEnter: () => {
				if (answerQuill.toolbar)
					answerQuill.toolbar.querySelectorAll('button').forEach((button) => button.disabled = true);
			},
			// Re-enable the toolbar when a text block is exited.
			textBlockExit: () => {
				if (answerQuill.toolbar)
					answerQuill.toolbar.querySelectorAll('button').forEach((button) => button.disabled = false);
			}
		};

		answerQuill.mathField = MQ.MathField(answerQuill, cfgOptions);

		answerQuill.textarea = answerQuill.querySelector('textarea');

		answerQuill.buttons = [
			{ id: 'frac', latex: '/', tooltip: 'fraction (/)', icon: '\\frac{\\text{ }}{\\text{ }}' },
			{ id: 'abs', latex: '|', tooltip: 'absolute value (|)', icon: '|\\text{ }|' },
			{ id: 'sqrt', latex: '\\sqrt', tooltip: 'square root (sqrt)', icon: '\\sqrt{\\text{ }}' },
			{ id: 'nthroot', latex: '\\root', tooltip: 'nth root (root)', icon: '\\sqrt[\\text{ }]{\\text{ }}' },
			{ id: 'exponent', latex: '^', tooltip: 'exponent (^)', icon: '\\text{ }^\\text{ }' },
			{ id: 'infty', latex: '\\infty', tooltip: 'infinity (inf)', icon: '\\infty' },
			{ id: 'pi', latex: '\\pi', tooltip: 'pi (pi)', icon: '\\pi' },
			{ id: 'vert', latex: '\\vert', tooltip: 'such that (vert)', icon: '|' },
			{ id: 'cup', latex: '\\cup', tooltip: 'union (union)', icon: '\\cup' },
			// { id: 'leq', latex: '\\leq', tooltip: 'less than or equal (<=)', icon: '\\leq' },
			// { id: 'geq', latex: '\\geq', tooltip: 'greater than or equal (>=)', icon: '\\geq' },
			{ id: 'text', latex: '\\text', tooltip: 'text mode (")', icon: 'Tt' }
		];

		answerQuill.hasFocus = false;

		// Open the toolbar when the mathquill answer box gains focus.
		answerQuill.textarea.addEventListener('focusin', () => {
			answerQuill.hasFocus = true;
			if (answerQuill.toolbar) return;

			answerQuill.toolbar = document.createElement('div');
			answerQuill.toolbar.classList.add('quill-toolbar');

			answerQuill.toolbar.tooltips = [];

			answerQuill.buttons.forEach((buttonData) => {
				const button = document.createElement('button');
				button.type = 'button';
				button.id = `${buttonData.id}-${answerQuill.id}`;
				button.classList.add('symbol-button', 'btn', 'btn-dark');
				button.dataset.latex = buttonData.latex;
				button.dataset.bsToggle = 'tooltip';
				button.dataset.bsTitle = buttonData.tooltip;
				const icon = document.createElement('span');
				icon.id = `icon-${buttonData.id}-${answerQuill.id}`;
				icon.textContent = buttonData.icon;
				button.append(icon);
				answerQuill.toolbar.append(button);

				MQ.StaticMath(icon, { mouseEvents: false });

				answerQuill.toolbar.tooltips.push(new bootstrap.Tooltip(button, {
					placement: 'left', trigger: 'hover', delay: { show: 500, hide: 0 }
				}));

				button.addEventListener('click', () => {
					answerQuill.hasFocus = true;
					answerQuill.mathField.cmd(button.dataset.latex);
					answerQuill.textarea.focus();
				})
			});
			document.body.append(answerQuill.toolbar);

			// This is covered by css for the standard toolbar sizes.  However, if buttons are added or removed from the
			// toolbar by the problem or if the window height is excessively small, those may be incorrect.  So this
			// adjusts the width in those cases.
			answerQuill.toolbar.adjustWidth = () => {
				if (!answerQuill.toolbar) return;
				const left =
					answerQuill.toolbar.querySelector('.symbol-button:first-child')?.getBoundingClientRect().left ?? 0;
				const right =
					answerQuill.toolbar.querySelector('.symbol-button:last-child')?.getBoundingClientRect().right ?? 0;
				answerQuill.toolbar.style.width = `${right - left + 8}px`;
			};
			window.addEventListener('resize', answerQuill.toolbar.adjustWidth);
			setTimeout(answerQuill.toolbar.adjustWidth);
		});

		answerQuill.textarea.addEventListener('focusout', (e) => {
			answerQuill.hasFocus = false;
			setTimeout(function() {
				if (!answerQuill.hasFocus && answerQuill.toolbar) {
					window.removeEventListener('resize', answerQuill.toolbar.adjustWidth);
					answerQuill.toolbar.tooltips.forEach((tooltip) => tooltip.dispose());
					answerQuill.toolbar.remove();
					delete answerQuill.toolbar;
				}
			}, 200);
		});

		// Trigger an answer preview when the enter key is pressed in an answer box.
		answerQuill.keypressHandler = (e) => {
			if (e.key == 'Enter') {
				// Ensure that the toolbar and any open tooltips are removed.
				answerQuill.toolbar?.tooltips.forEach((tooltip) => tooltip.dispose());
				answerQuill.toolbar?.remove();
				delete answerQuill.toolbar;

				// For ww2 homework
				document.getElementById('previewAnswers_id')?.click();
				// For gateway quizzes
				document.querySelector('input[name=previewAnswers]')?.click();
				// For ww3
				const previewButtonId =
					answerQuill.textarea.closest('[name=problemMainForm]')?.id
						.replace('problemMainForm', 'previewAnswers');
				if (previewButtonId) document.getElementById(previewButtonId)?.click();
			}
		};
		answerQuill.addEventListener('keypress', answerQuill.keypressHandler);

		answerQuill.mathField.latex(answerQuill.latexInput.value);
		answerQuill.mathField.moveToLeftEnd();
		answerQuill.mathField.blur();

		// Look for a result in the attempts table for this answer.
		document.querySelectorAll('td a[data-answer-id]').forEach((tableLink) => {
			// Give the mathquill answer box the correct/incorrect colors.
			if (answerLabel.includes(tableLink.dataset.answerId)) {
				if (tableLink.parentNode.classList.contains('ResultsWithoutError'))
					answerQuill.classList.add('correct');
				else answerQuill.classList.add('incorrect');
			}

			// Make a click on the results table link give focus to the mathquill answer box.
			if (answerLabel === tableLink.dataset.answerId) {
				tableLink.addEventListener('click', (e) => {
					e.preventDefault();
					answerQuill.textarea.focus();
				});
			}
		});

		window.answerQuills[answerLabel] = answerQuill;
	};

	// Set up MathQuill inputs that are already in the page.
	document.querySelectorAll('[id^=MaThQuIlL_]').forEach((input) => setupMQInput(input));

	// Observer that sets up MathQuill inputs.
	const observer = new MutationObserver((mutationsList) => {
		mutationsList.forEach((mutation) => {
			mutation.addedNodes.forEach((node) => {
				if (node instanceof Element) {
					if (node.id && node.id.startsWith('MaThQuIlL_')) {
						setupMQInput(node);
					} else {
						node.querySelectorAll('input[id^=MaThQuIlL_]').forEach((input) => setupMQInput(input));
					}
				}
			});
		});
	});
	observer.observe(document.body, { childList: true, subtree: true });

	// Stop the mutation observer when the window is closed.
	window.addEventListener('unload', () => observer.disconnect());
})();
