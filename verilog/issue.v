`ifndef _include_issue_
`define _include_issue_

module Issue(
    );
     
    /*
    * This is a skeleton for the issue stage.
    * Issue should:
    *   Hold or be able to connect to 1 or more Allocators
    *   Describe the position of each allocator
    *   Walk over the image in order and send pixel values to all allocators
    *
    * Getting data into image memory is out of scope (for now).
    *
    * Currently undetermined:
    *   Should the image issue also hold filter values, or should they be
    *       handled by separate blocks?
    *   Should each Allocator's X and Y be continuously defined, or should
    *       they be stored in a register?
    */

   /*
    * DSP positioning
    *
    * The issue stage should be able to take N attached DSPs, 1<=N<=220, and
    * assign their center_x and center_y signals. 
    *
    * Padding is handled in the issue stage. For a 3x3 filter, the minimum
    * allowed center is (1,1), and for a 5x5 (2,2). This may require
    * offsetting the image coordinates.
    *
    * It is possible, but not guaranteed, that the number of pixels will
    * exceed the number of available DSPs. In that event, Issue should assign
    * going first across the image, then down. The issue should perform a walk
    * over these pixels (more later), read the outputs, and then reposition
    * the allocators, repeating until all pixels have been covered.
    *
    * Strides will be handled by DSP position assignment.
    */

   /*
    * Image walking
    *
    * When all Allocators have been positioned, the issue stage should begin
    * walking over each pixel and broadcasting pixel values. 
    *
    * The walk should cover each pixel that is a dependency of the filter
    * computation exactly once, and in-order. Each broadcasted pixel should
    * provide its x and y coordinates, and its value. 
    *
    * The flowchart that was on the whiteboard on 18 March 2018 describes
    * a process to walk across pixels with no waste and in the correct order.
    *
    * Each Allocator may raise a "issue_block" signal. If any Allocator raises
    * this signal, Issue should pause walking and raise the "issue_blocked"
    * signal. 
    */

    
`endif // _include_issue_
