`ifdef SDF
module sdf_annotate;
  initial begin
    $sdf_annotate(`SDF_FILE, TestDriver.testHarness.chiptop0, , "sdf_annotation.log", "MAXIMUM");
  end
endmodule
`endif
