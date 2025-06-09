// AXI4-Stream位宽转换模块

module axis_width_converter #(
  parameter interger S_TDATA_WIDTH = 0, // 1-512 (byte)
  parameter interger M_TDATA_WIDTH = 0, // 1-512 (byte)
  parameter interger TID_WIDTH = 0, // 0-32 (bit)
  parameter interger TDEST_WIDTH = 0, // 0-32 (bit)
  parameter interger TUSER_WIDTH_PER_BYTE = 0 // 0-2048 (bit)
)(
  input                                           aclk,
  input                                           aresetn,

  input                                           s_axis_tvalid,
  output                                          s_axis_tready,
  input  [S_TDATA_WIDTH*8-1:0]                    s_axis_tdata,
  input  [S_TDATA_WIDTH-1:0]                      s_axis_tstrb,
  input  [S_TDATA_WIDTH-1:0]                      s_axis_tkeep,
  input                                           s_axis_tlast,
  input  [TID_WIDTH-1:0]                          s_axis_tid,
  input  [TDEST_WIDTH-1:0]                        s_axis_tdest,
  input  [S_TDATA_WIDTH*TUSER_WIDTH_PER_BYTE-1:0] s_axis_tuser,

  output                                          m_axis_tvalid,
  input                                           m_axis_tready,
  output [M_TDATA_WIDTH*8-1:0]                    m_axis_tdata,
  input  [M_TDATA_WIDTH-1:0]                      m_axis_tstrb,
  input  [M_TDATA_WIDTH-1:0]                      m_axis_tkeep,
  input                                           m_axis_tlast,
  input  [TID_WIDTH-1:0]                          m_axis_tid,
  input  [TDEST_WIDTH-1:0]                        m_axis_tdest,
  input  [M_TDATA_WIDTH*TUSER_WIDTH_PER_BYTE-1:0] m_axis_tuser
);
  
generate
  if (S_TDATA_WIDTH == M_TDATA_WIDTH)
    begin
      assign m_axis_tvalid = s_axis_tvalid;
      assign s_axis_tready = m_axis_tready;
      assign m_axis_tdata = s_axis_tdata;
      assign m_axis_tstrb = s_axis_tstrb;
      assign m_axis_tkeep = s_axis_tkeep;
      assign m_axis_tlast = s_axis_tlast;
      assign m_axis_tid = s_axis_tid;
      assign m_axis_tdest = s_axis_tdest;
      assign m_axis_tuser = s_axis_tuser;
    end
  else if (S_TDATA_WIDTH < M_TDATA_WIDTH)
    begin








    end
  else // S_TDATA_WIDTH > M_TDATA_WIDTH
    begin
      
    end
endgenerate

endmodule



  generate
    // if they are the same... there really isn't a point.
    if(SLAVE_WIDTH == MASTER_WIDTH) begin : gen_EQUAL_WIDTH
      assign m_axis_tdata  = s_axis_tdata;
      assign m_axis_tvalid = s_axis_tvalid;
      assign s_axis_tready = m_axis_tready;
      assign m_axis_tlast  = s_axis_tlast;
    // slave is smaller, use register build up method. (increase)
    end else if(SLAVE_WIDTH < MASTER_WIDTH) begin : gen_SLAVE_SMALL
      //buffer
      reg [(SLAVE_WIDTH*8)-1:0]  reg_data_buffer[MASTER_WIDTH/SLAVE_WIDTH-1:0];
      reg reg_data_valid;
      reg reg_data_last;
      //counter
      reg [clogb2(MASTER_WIDTH):0] counter;
      //index
      reg [clogb2(MASTER_WIDTH):0] index;
      
      reg p_m_axis_tready;
      
      //when ready lets let the component feeding us know.
      assign s_axis_tready  = (m_axis_tready | ~p_m_axis_tready) & arstn;
      //send out a reg valid to match reg data
      assign m_axis_tvalid  = reg_data_valid;
      //send out a reg tlast to match reg data
      assign m_axis_tlast = reg_data_last & reg_data_valid;
      
      //generate wires to connect reg_data_buffer to tdata out. reg_valid selects buffer if data is valid.
      for(gen_index = 0; gen_index < (MASTER_WIDTH/SLAVE_WIDTH); gen_index = gen_index + 1) begin : gen_DATA_ROUTING
        assign m_axis_tdata[(8*SLAVE_WIDTH*(gen_index+1))-1:8*SLAVE_WIDTH*gen_index] = (reg_data_valid == 1'b1 ? reg_data_buffer[gen_index] : 0);
      end
      
      //process data
      always @(posedge aclk) begin
        //clear all
        if(arstn == 1'b0) begin
          for(index = 0; index < (MASTER_WIDTH/SLAVE_WIDTH); index = index + 1) begin
            reg_data_buffer[index] <= 0;
          end
          reg_data_valid    <= 0;
          reg_data_last     <= 0;
          counter           <= (REVERSE == 0 ? 0 : (MASTER_WIDTH/SLAVE_WIDTH)-1);
          p_m_axis_tready   <= 0;
        end else begin
          //when ready, 0 out data so we don't send out the same thing over and over.
          //if we are still sending data, the if below will blow this up (in a good way).
          if(m_axis_tready == 1'b1) begin
            reg_data_valid  <= 0;
            reg_data_last   <= 0;
            //no valid data, so lets 0 out previous to allow a valid assert of data without ready to happen.
            p_m_axis_tready <= 0;
          end
          
          //valid data and we are ready for data, or per axis standard we pump out valid data and wait for ready to continue.
          if((s_axis_tvalid == 1'b1) && (~p_m_axis_tready || m_axis_tready)) begin
            reg_data_buffer[counter] <= s_axis_tdata;
            
            reg_data_last <= reg_data_last | s_axis_tlast;
            
            p_m_axis_tready <= 1'b1;
            
            counter <= (REVERSE == 0 ? counter + 1 : counter - 1);
            
            if(counter == (REVERSE == 0 ? (MASTER_WIDTH/SLAVE_WIDTH)-1 : 0)) begin
              counter         <= (REVERSE == 0 ? 0 : (MASTER_WIDTH/SLAVE_WIDTH)-1);
              reg_data_valid  <= 1;
            end
          end
        end
      end
    // slave input is larger then master register method (reduce)
    end else begin : gen_SLAVE_LARGE
      //buffer
      reg [(MASTER_WIDTH*8)-1:0] reg_data_buffer[SLAVE_WIDTH/MASTER_WIDTH-1:0];
      reg                        reg_data_valid;
      reg                        reg_data_last[SLAVE_WIDTH/MASTER_WIDTH-1:0];
      reg [(MASTER_WIDTH*8)-1:0] reg_m_axis_tdata;
      
      //counter
      reg [clogb2(SLAVE_WIDTH):0] counter;
      //index
      reg [clogb2(SLAVE_WIDTH):0] index;
      
      //split s_axis
      wire [(MASTER_WIDTH*8)-1:0] split_s_axis_tdata[SLAVE_WIDTH/MASTER_WIDTH-1:0];
      
      //m_axis_tready
      reg p_m_axis_tready;
      
      //split slave tdata into pieces the size of master tdata
      for(gen_index = 0; gen_index < (SLAVE_WIDTH/MASTER_WIDTH); gen_index = gen_index + 1) begin : gen_SLAVE_SPLIT
        assign split_s_axis_tdata[gen_index] = s_axis_tdata[(8*MASTER_WIDTH*(gen_index+1))-1:8*MASTER_WIDTH*gen_index] ;
      end
      
      //only ready when taking in data or if conditons say so.
      assign s_axis_tready = (counter == (SLAVE_WIDTH/MASTER_WIDTH)-1 ? (~p_m_axis_tready | m_axis_tready) & arstn : 1'b0);
      //output for master axis data
      assign m_axis_tdata  = (reg_data_valid == 1'b1 ? reg_data_buffer[counter] : 0);
      assign m_axis_tvalid = reg_data_valid;
      assign m_axis_tlast  = (reg_data_valid == 1'b1 ? reg_data_last[counter] : 0);
      
      //process data
      always @(posedge aclk) begin
        //clear all
        if(arstn == 1'b0) begin
          for(index = 0; index < (SLAVE_WIDTH/MASTER_WIDTH); index = index + 1) begin
            reg_data_buffer[index] <= 0;
            reg_data_last[index]   <= 0;
          end
          reg_data_valid    <= 0;
          reg_m_axis_tdata  <= 0;
          counter           <= (REVERSE == 0 ? (SLAVE_WIDTH/MASTER_WIDTH)-1 : 0);
          p_m_axis_tready   <= 0;
        end else begin
          //when ready, 0 out data so we don't send out the same thing over and over.
          //if we are still sending data, the if below will blow this up (in a good way).
          if(m_axis_tready == 1'b1) begin
            reg_data_valid  <= 0;
            //no valid data, so lets 0 out previous to allow a valid assert of data without ready to happen.
            p_m_axis_tready <= 0;
          end
          
          //when data is valid, counter is correct, and we are ready for data
          //(p tready tells if we have ever been, and allows for valid data to be output first if not, per axis standard).
          //Then lets register some new data, and reset the counter to 1 to output this new data starting at its top.
          if((s_axis_tvalid == 1'b1) && (counter == (REVERSE == 0 ? (MASTER_WIDTH/SLAVE_WIDTH)-1 : 0)) && (~p_m_axis_tready || m_axis_tready)) begin
            for(index = 0; index < (SLAVE_WIDTH/MASTER_WIDTH); index = index + 1) begin
              reg_data_buffer[index] <= split_s_axis_tdata[index];
              reg_data_last[index] <= ((index == (SLAVE_WIDTH/MASTER_WIDTH)-1) ? s_axis_tlast : 0);
            end
            
            counter <= (REVERSE == 0 ? 0 : (SLAVE_WIDTH/MASTER_WIDTH)-1);
            
            reg_data_valid  <= 1'b1;
            
            p_m_axis_tready <= 1'b1;
          end
          
          //only decrease the counter when its not 0 (underrun prevention) and the next core is ready for more data.
          if((counter != (REVERSE == 0 ? (MASTER_WIDTH/SLAVE_WIDTH)-1 : 0)) && (m_axis_tready == 1'b1)) begin
            counter         <= (REVERSE == 0 ? counter + 1 : counter - 1);
            reg_data_valid  <= 1'b1;
            p_m_axis_tready <= 1'b1;
          end         
        end
      end
    end
  endgenerate