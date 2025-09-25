import os
import sys
sys.path.insert(0, os.path.abspath('..'))

project = 'CortPro'
author = 'Casey Paquola'
release = '0.1'

extensions = [
    'sphinx_rtd_theme',
    'sphinx_tabs.tabs',
    'sphinx_gallery.gen_gallery',
]

html_theme = 'sphinx_rtd_theme'
html_static_path = ['_static']
html_logo = "_static/cortpro_logo.png"
html_theme_options = {
    "navigation_depth": 3,
    "collapse_navigation": False,
    "style_nav_header_background": "#4e799e",
}
