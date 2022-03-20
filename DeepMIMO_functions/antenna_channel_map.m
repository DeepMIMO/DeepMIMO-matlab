function antenna_map = antenna_channel_map(x, y, z, string)

    Mx_Ind=0:1:x-1;
    My_Ind=0:1:y-1;
    Mz_Ind=0:1:z-1;
    Mxx_Ind=repmat(Mx_Ind, 1, y*z)'; %col vector
    Myy_Ind=repmat(reshape(repmat(My_Ind,x,1), 1, x*y), 1, z)'; %col vector
    Mzz_Ind=reshape(repmat(Mz_Ind,x*y,1), 1, x*y*z)'; %col vector
    if string
        antenna_map = cellstr([num2str(Mxx_Ind) num2str(Myy_Ind) num2str(Mzz_Ind)]);
    else
        antenna_map = [Mxx_Ind, Myy_Ind, Mzz_Ind];
    end
end