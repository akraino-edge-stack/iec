.. This work is licensed under a Creative Commons Attribution 4.0 International License.
.. SPDX-License-Identifier: CC-BY-4.0
.. (c) 2019 Akraino IEC

===========================================
Akraino IEC Submodule Fetching and Patching
===========================================

This directory holds submodule fetching/patching scripts, intended for
working with upstream IEC components in developing/applying Akraino
patches (backports, custom fixes etc.).

The scripts should be friendly to the following 2 use-cases:

- development work: easily cloning, binding repos to specific commits,
  remote tracking, patch development etc.;
- to provide parent build scripts an easy method of tracking upstream
  references and applying Akraino patches on top;

Also, we need to support at least the following modes of operations:

- submodule bind - each submodule patches will be based on the commit ID
  saved in the ``.gitmodules`` config file;
- remote tracking - each submodule will sync with the upstream remote
  and patches will be applied on top of ``<sub_remote>/<sub_branch>/HEAD``;

Workflow (Development)
======================

The standard development workflow should look as follows:

Decide whether remote tracking should be active or not
------------------------------------------------------

.. NOTE::

    Setting the following var to any non-empty str enables remote track.

.. code-block:: console

    developer@machine:~/iec$ export IEC_TRACK_REMOTES=""

Initialize git submodules
-------------------------

All IEC direct dependency projects are registered as submodules.
If remote tracking is active, upstream remote is queried and latest remote
branch ``HEAD`` is fetched. Otherwise, checkout commit IDs from ``.gitmodules``.

.. code-block:: console

    developer@machine:~/iec$ make -C src/use_cases sub

Apply patches from ``patches/<sub-project>/*`` to respective submodules
-----------------------------------------------------------------------

This will result in creation of:

- a tag called ``${IEC_TAG}-root`` at the same commit as Akraino IEC
  upstream reference (bound to git submodule OR tracking remote ``HEAD``);
- a new branch ``nightly`` which will hold all the IEC patches,
  each patch is applied on this new branch with ``git-am``;
- a tag called ``${IEC_TAG}`` at ``nightly/HEAD``;
- for each (sub)directory of ``patches/<sub-project>``, another pair of tags
  ``${IEC_TAG}-<sub-directory>-iec/patch-root`` and
  ``${IEC_TAG}-<sub-directory>-iec/patch`` are also created;

.. code-block:: console

    developer@machine:~/iec$ make -C src/use_cases patches-import

Modify sub-projects for whatever you need
-----------------------------------------

To add/change IEC-specific patches for a sub-project:

- commit your changes inside the git submodule(s);
- move the git tag to the new reference so ``make patches-export`` will
  pick up the new commit later;

.. code-block:: console

    developer@machine:~/iec$ cd ./path/to/submodule
    developer@machine:~/iec/path/to/submodule$ # ...
    developer@machine:~/iec/path/to/submodule$ git commit
    developer@machine:~/iec/path/to/submodule$ git tag -f ${IEC_TAG}-iec/patch

Re-create Patches
-----------------

Each commit on ``nightly`` branch of each subproject will be
exported to ``patches/subproject/`` via ``git format-patch``.

.. NOTE::

    Only commit submodule file changes when you need to bump upstream refs.

.. WARNING::

    DO NOT commit patched submodules!

.. code-block:: console

    developer@machine:~/iec$ make -C src/use_cases patches-export patches-copyright

Clean Workbench Branches and Tags
---------------------------------

.. code-block:: console

    developer@machine:~/iec$ make -C src/use_cases clean

De-initialize Submodules and Force a Clean Clone
------------------------------------------------

.. code-block:: console

    developer@machine:~/iec$ make -C src/use_cases deepclean

Sub-project Maintenance
=======================

Adding a New Submodule
----------------------

If you need to add another subproject, you can do it with ``git submodule``.
Make sure that you specify branch (with ``-b``), short name (with ``--name``):

.. code-block:: console

    developer@machine:~/iec$ git submodule -b v1.1.2 add --name zookeeper_exporter \
                             https://github.com/josdotso/zookeeper_exporter \
                             src/use_cases/seba_on_arm/src_repo/zookeeper_exporter

Working with Remote Tracking
----------------------------

Enable remote tracking as described above, which at ``make sub`` will update
ALL submodules to remote branch (set in ``.gitmodules``) ``HEAD``.

.. WARNING::

    Enforce ``IEC_TRACK_REMOTES`` to ``yes`` only if you want to constatly
    use the latest remote branch ``HEAD`` (as soon as upstream pushes a change
    on that branch, our next build will automatically include it - risk of our
    patches colliding with new upstream changes) - for **ALL** submodules.
