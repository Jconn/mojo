<?xml version="1.0" encoding="UTF-8"?>
<project name="PotentioLED-V" board="Mojo V3" language="Verilog">
  <files>
    <src top="true">mojo_top.v</src>
    <src>avr_interface.v</src>
    <src>serial_tx.v</src>
    <src>serial_rx.v</src>
    <src>spi_master.v</src>
    <src>sine_synth.v</src>
    <src>audio_filter.v</src>
    <src>cclk_detector.v</src>
    <src>speaker.v</src>
    <src>IIR.v</src>
    <src>spi_slave.v</src>
    <src>pwm.v</src>
    <src>input_capture.v</src>
    <ucf>mojo.ucf</ucf>
    <component>simple_ram.v</component>
    <core name="dds_compiler_v5_0">
      <src>dds_compiler_v5_0.ngc</src>
      <src>dds_compiler_v5_0.v</src>
    </core>
  </files>
</project>
