function[S,xc,yc,zc,correct]= rtkmain(data)
% 双频RTK函数
format long;
%% 初始化

Global(2);
mode = 2;

%{
--------------初始化-----------------
data = 1  ------ 选择数据             |
Global(1) -----  导航系统GPS          |
Global(2) -----  导航系统BDS          |
mode = 1  -----  意思为单频           |
mode = 2  -----  意思是双频           |
--------------初始化------------------
%}


%% 读取文件
% [navdata,navfilepath]=readnavfile;                              %得到卫星的星历文件nav
% [basedata,basefilepath]=readobsfile;                            %得到基站接收机星历文件base
% [obsdata,movefilepath]=readobsfile;                             %得到用户接收机星历文件obs

%% 数据及基准坐标

switch (data)
    case 1
        x0=[-2364337.3977;4870285.6075;-3360809.7103];
        x1 = x0;
        load('14p16804_21cut0cut2.mat');
    case 2
        x0 = [-2364337.4414;4870285.6211;-3360809.6724];
        x1 = x0;
        load('16p16804_24cut0cut2.mat');
    case 3
        x0= [-2364335.4220;4870281.4604;-3360816.7056];
        x1= [-2364337.4414;4870285.6211;-3360809.6724];
        load('16p16804_24cutacut0.mat');
    case 4
        x0 = [-2364337.4414;4870285.6211;-3360809.6724];
        x1 = x0;
        load('14p04504_24cut0cut2.mat');
    case 5
        x0 = [-2364337.4414;4870285.6211;-3360809.6724];
        x1 = [-2364335.4220;4870281.4604;-3360816.7056];
        load('14p04504_24cut0cuta.mat');
    case 6
        x0 = [-2364337.4414;4870285.6211;-3360809.6724];
        x1= x0;
        load('16p32404_25cut1cut3.mat');
    case 7
        x0=[-2364337.3977;4870285.6075;-3360809.7103];
        x1 = x0;
        load('shuangpin14p16804_21cut0cut2.mat');
    case 8
        x0 = [-2364337.4414;4870285.6211;-3360809.6724];
        x1 = x0;
        load('shuangpin15p03904_27cut0cut2.mat');
    case 9
        x0 = [-2364337.4414;4870285.6211;-3360809.6724];
        x1 = [-2364335.4220;4870281.4604;-3360816.7056];
        %         x2 = [-2364333.5346;4870287.3393;-3360809.5251];
        load('shuangpin16p16804_27cut0cuta.mat');
    case 10
        x0 = [-2364337.4414;4870285.6211;-3360809.6724];
        x1 = [-2364333.5346;4870287.3393;-3360809.5251];
        %         x2 = [-2364335.4220;4870281.4604;-3360816.7056];
        load('shuangpin16p16804_27cut0cutb.mat');
    case 11
        x0 = [-2364335.4220;4870281.4604;-3360816.7056];
        x1 = [-2364333.5346;4870287.3393;-3360809.5251];
        load('shuangpin16p16804_27cutacutb.mat');
    case 12
        x0 = [-2364337.4414;4870285.6211;-3360809.6724];
        x1 = [-2364333.5346;4870287.3393;-3360809.5251];
        %         x2 = [-2364335.4220;4870281.4604;-3360816.7056];
        load('shuangpin16p16806_5cut0cutb.mat');
    case 13
        x0 = [-2364337.4414;4870285.6211;-3360809.6724];
        x1 = [-2364335.4220;4870281.4604;-3360816.7056];
        %         x2 = [-2364333.5346;4870287.3393;-3360809.5251];
        load('shuangpin16p16806_11cut0cuta.mat');
end

%% 求取转换矩阵S
global f a
e=sqrt(f*(2-f));
lambda=atan2(x0(2),x0(1));
phi=0;
for i=1:4
    N=a/sqrt(1-e^2*(sin(phi))^2);
    p=sqrt(x0(1)^2+x0(2)^2);
    h=p/cos(phi)-N;
    phi=atan(x0(3)/(p*(1-(N/(N+h))*e^2)));
end
S=[-sin(lambda) cos(lambda) 0;...
    -sin(phi)*cos(lambda) -sin(phi)*sin(lambda) cos(phi);...
    cos(phi)*cos(lambda) cos(phi)*sin(lambda) sin(phi)];

%% 单频情况下利用单点定位求取未固定位置
if (mode == 1)
    [SPx,SPy,SPz]=SP(x0,navfilepath,movefilepath);
end


%% RTK
wrong=0;
correct=0;
h=waitbar(0,'请等待...');
group=2880;
for m=1:group
    
    [basesat,basenum]= SateposAndC1c(navdata,basedata,x0,S,m);
    [movesat,obsnum] = SateposAndC1c(navdata,obsdata,x0,S,m);
    [singaldiff,satnum,maxnum] = SD(basesat,basenum,movesat,obsnum,x0);
    if     (mode ==1)
        [N,d,Qxn,Qn,DDsatnum] = DDS(singaldiff,satnum,maxnum);
    elseif (mode ==2)
        [N,d,Qxn,Qn,DDsatnum] = DDD(singaldiff,satnum,maxnum);
    end
    %-----模糊度固定----%
    clear afixed sqnorm Ps Qzhat Z nfixed mu;
    [afixed,sqnorm,Ps,Qzhat,Z,nfixed,mu]= LAMBDA (N,Qn,6,'MU',1/3);
    proba(m)=(nfixed==DDsatnum);
    clear Nf;
    Nf =afixed(:,1);
    %------修正基线-----%
    df=d-Qxn/Qn*(N-Nf);
    pos=x0+df;
    if(proba(m)==0)
        wrong=wrong+1;
        if(mode == 1)
            x(m) = SPx(m);
            y(m) = SPy(m);
            z(m) = SPz(m);
        else
            posDD = x0 + d ;
            x(m) = posDD(1);
            y(m) = posDD(2);
            z(m) = posDD(3);
        end
    else
        correct=correct+1;
        P(correct)=Ps;
        Dp(:,correct)=df;
        %----修正后的坐标值----%
        x(m) = pos(1);
        y(m) = pos(2);
        z(m) = pos(3);
        xc(correct) = pos(1);
        yc(correct) = pos(2);
        zc(correct) = pos(3);
    end
    
    %--- 求取误差--%
    dx(m) = x(m)-x1(1);
    dy(m) = y(m)-x1(2);
    dz(m) = z(m)-x1(3);
    %-----求取CEP----%
    env=S*[dx(m);dy(m);dz(m)];
    CEPL(m) = sqrt(env(1)^2+env(2)^2) ;
    CEPH(m) = env(3);
    
    %-----卫星数目----%
    st(m) = satnum;
    string = ['正在运行中',num2str(floor(m/group*100)),'%'];
    waitbar(m/group,h,string);
end

close(h);
end





