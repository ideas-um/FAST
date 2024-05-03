# **How to Contribute**

Copyright 2024 The Regents of the University of Michigan, The Integrated Design of Environmentally-friendly Aircraft Systems Laboratory

How to Contribute to FAST

Written by the IDEAS Lab at the University of Michigan
<https://ideas.engin.umich.edu>

Principal Investigator and Point of Contact:
- Dr. Gokcin Cinar, <cinar@umich.edu>

Principal Authors:
- Paul Mokotoff, <prmoko@umich.edu>
- Max Arnson, <marnson@umich.edu>

Last Updated: 02 may 2024

# Steps to Contribute:

1. Fork the repository from GitHub. This can be done by accessing the code from **insert GitHub link here** and clicking the "Fork" button to the right of the repository name. Forking allows anyone to make changes to the code without impacting FAST's existing functionality. Furthermore, it maintains a connection to the root repository that the fork was created from. This allows the forked repository to be updated from the main (upstream) repository at any time.
2. Modify the code as desired. Users are allowed to add any functionality that they desire. Please take note of the code conventions described in a later section of this document. Also, it is recommended to make small commits for every function or feature change. That way, the reviewers can easily understand the changes made in each function within the commit.
3. Create a pull request in GitHub. This will alert the owners of FAST that someone wants to add a new feature to FAST. It will be reviewed and any necessary changes will be made known to the author that generated the pull request. Any contributor is required to share their name and email with the FAST developers. All contributors are welcome to optionally share their affiliation as well.

    If the pull request is approved by the FAST developers, then it will be added to the latest version of FAST. If the pull request is declined, feedback about the code will be provided.

# Coding Conventions:

There are multiple coding conventions within FAST. Please take note of these and follow them in any code that someone seeks to contribute to FAST.

### Function Headers

In each function that is shipped with FAST, a specific function header is created to provide documentation for a user to understand how the function should be called, along with descriptions of the function's capabilities and the inputs/outputs.

All function headers must be formatted as:

```matlab
%
% [OutArg1, ..., OutArgN] = FunctionName(InArg1, ..., InArgN)
% written by <Author Name>, <Author Email>
% last updated: <dd> <mmm> <yyyy>
%
% <function description>
%
% INPUTS:
%     InArg1  - <input description>
%               size/type/units: <size> / <type> / [<units>]
%
%     ...
%
%     InArgN  - <input description>
%               size/type/units: <size> / <type> / [<units>]
%
% OUTPUTS:
%     OutArg1 - <output description>
%               size/type/units: <size> / <type> / [<units>]
%
%     ...
%
%     OutArgN - <output description>
%               size/type/units: <size> / <type> / [<units>]
%
```

All InArg* and OutArg* names should be replaced with the appropriate input and output variable names, respectively. Additionally, any text enclosed with \<brackets\> needs to be updated by the user.

Each person that contributes to a function should include their name in the \<AuthorName\> and \<AuthorEmail\>. If more than one author contributes to the code, either list all of the authors in one line or list each author on consecutive lines (either option is welcome, the latter is recommmended).

For the date in which the code was last updated, \<dd\> is the day, \<mmm\> is the three-letter abbreviation for the month, and \<yyyy\> is the year. An example of this is:

> 04 apr 2024

After this information is listed, provide a description of the newly written function in the \<function description\> section.

All input and output arguments must be listed, along with a description of what they represent (indicated by the \<input description\> and \<output description\> prompts, respectively). Additionally, details about the variable size, type, and units (if any) are required. The \<type\> is always one of the Matlab data types (int, double, struct, string, etc.). The \<size\> represents the expected size of the variable being input/output. Typically, a variable with a single letter (like "n" in the example below) is used to represent a vector with a variable number of entries - this can be extended for multi-dimensional arrays. Also, variables with no units should only include "[]" rather than leaving the \<units\> portion of completely blank.

Some examples of input/output descriptions are:

```matlab
Density  - the density at the current altitude.
           size/type/units: n-by-1 / double / [kg/m^3]

Lambda   - the power split.
           size/type/units: 1-by-1 / double / [%]

Aircraft - a data strcture containing information about
           the aircraft being analyzed.
           size/type/units: 1-by-1 / struct / []
```

### Variable Naming

When writing code in FAST, please note the variable naming conventions that are used throughout the code:

- All function names and most variables are named using PascalCase, which capitalizes the first letter in each word. There are a few exceptions to using PascalCase for variables, which are explained in the next item on this list. Example variable names include "PowerRequired" or "Aircraft".
- The times that it is okay to use all lowercase for variable names are counters/indices and mathematical values or constants that warrant a lowercase letter (like acceleration due to gravity or a differential). Example variable names include "i", "dTime", "g", or "npnt".
- All abbreviations should be named with UPPERCASE letters. Examples include "PE" for potential energy, "KE" for kinetic energy, "TAS" for true airspeed, or "EAS" for equivalent airspeed.
- Lastly, use an underscore (_) to represent a fraction. This is useful for displaying mathematical quantities as variable names. Examples include "dV_dt" for dV/dt, "L_D" for lift-drag ratio, and "dh_dt" for dh/dt.

### Additional Coding Conventions (strongly recommended)

- When printing any warnings, errors, messages to the command line, etc., please use strings (delineated by " ") not character arrays (delineated by ' ').
- If multiple equations are on consecutive lines, please try to vertically align them, if appropriate. Two examples are:

```matlab
% compute the power to overcome altitude and acceleration
dPE_dt = Mass .* g   .* dh_dt;
dKE_dt = Mass .* TAS .* dV_dt;
```

or

```matlab
% store the information
Performance.Dist(SegBeg:SegEnd) = Dist ;
Performance.EAS( SegBeg:SegEnd) = EAS  ;
Performance.RC(  SegBeg:SegEnd) = dh_dt;
Performance.Acc( SegBeg:SegEnd) = dV_dt;
```

### Using Sections and Sub-Sections:

Sections and sub-sections are a useful way to divide a function into smaller, more meaningful blocks of code. That way, anyone reading the code can better understand what is going on and has access to a high-level summary of what the code block is doing.

Sections are denoted with two percent signs (%%) at the beginning and end of the section name, followed by another line of percent signs matching the length of the line above it. All letters in a section header should be UPPERCASE. An example is:

```matlab
%% AIRCRAFT ANALYSIS %%
%%%%%%%%%%%%%%%%%%%%%%%
```

Also, there should be two blank lines in-between successive sections. For example:

```matlab
%% AIRCRAFT ANALYSIS %%
%%%%%%%%%%%%%%%%%%%%%%%

<code>


%% NEW SECTION STARTS HERE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

<code>
```

When providing a name for a section, try to make it a short, concise summary of what that code block does or what its purpose is.

If the function being added to FAST is very short (less than 50 lines of actual code), then it is likely that section headers are not needed. Sub-section headers (described next) may be used, or no section/sub-section headers at all.

Sub-sections are used within sections of code to convey a little more detail about what a specific code block is doing. Typically, the section is used to describe the high-level task being performed and sub-sections will define a medium- or low-level task that is being performed.

Sub-sections are formatted as a "block" of percent signs (%) that is always 30 percent signs (%) wide. An example is:

```matlab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% <sub-section description   %
%  goes here>                %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
```

Notice that the sub-section comment can be multiple lines long, if needed (unlike section comments, which are much more concise). Please make sure to include a line of space between the lines of percent signs (as shown in the example above).

If multiple sub-sections are used within a section, then a divider should be included. A divider is a commented line with many dashes (-) that stop after the 60th character in the line has been reached. An example of this is:

```matlab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% first sub-section          %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

<code>

% --------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% second sub-section         %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

<code>
```

Both the sub-section headers and dividers should be indented if they are displayed within "for", "if", etc. blocks. Section headers, however, should not be nested (and therefore, never indented).

### Commenting:

Please comment code frequently and clearly. Most of the code in FAST has a comment for each line that is written. This is to ensure that the code is understandable to someone else that will be using the tool (or developing code in the future). In addition requests will be checked for well-documented and commented code.

In terms of formatting, most in-line comments are written in all lowercase letters. Occassionally, it may be neccessary (and permissible) to Capitalize a word in the commment - do this only if it is an important word and must be distinguished from other words. Please try to refrain from using all UPPERCASE letters in the in-line comments - those should be saved for code section headers.

# Additional Notes about Contributing:

- Any contributor that generates a pull request and wants to merge their contributions into FAST must provide their name and email address. Optionally, contributors are welcome to provide their affiliation.
- FAST is licensed under the Apache License, Version 2.0. Please consult the "EULA.m" files for more information. The Apache License, Version 2.0 can be found at:

    > <http://www.apache.org/licenses/LICENSE-2.0>

    This license allows any user of FAST to make changes to the code (known as "Derivative Works" in the Apache License, Version 2.0).

    Therefore, anybody using FAST is welcome to change the code and write code in any desired style. However, code that will be submitted to the original developers in the form of a pull request must be written in the style described above.

- Please direct any questions about contributing to the repository to the point of contact listed at the beginning of this file.

**end Contributions**