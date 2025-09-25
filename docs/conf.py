# Configuration file for the Sphinx documentation builder.
#
# This file only contains a selection of the most common options. For a full
# list see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Path setup --------------------------------------------------------------

# If extensions (or modules to document with autodoc) are in another directory,
# add these directories to sys.path here. If the directory is relative to the
# documentation root, use os.path.abspath to make it absolute, like shown here.
#
import os
import sys
sys.path.insert(0, os.path.abspath('..'))

# -- Project information -----------------------------------------------------

project = 'CortPro'
author = 'Casey Paquola'
release = '0.1'

# -- General configuration ---------------------------------------------------

extensions = [
    'sphinx_rtd_theme',   # main ReadTheDocs theme
    # 'myst_parser',       # enable if you want Markdown support
    # 'sphinx.ext.autodoc', # enable if you want autodoc for Python code
]

templates_path = ['_templates']
exclude_patterns = []

# -- Options for HTML output -------------------------------------------------

html_theme = 'sphinx_rtd_theme'
html_static_path = ['_static']

# -- Custom sidebar/logo options (optional) ----------------------------------

# You can add a logo if you have one:
html_logo = "_static/cortpro_logo.png"

# Use wide sidebar for navigation
html_theme_options = {
    "navigation_depth": 3,
    "collapse_navigation": False,
    "style_nav_header_background": "#4e799e",  # matches your blue accent
}
