%% Resetando
clear;
clc;
close all;
show_plot = 1;

values = [4 5 10 15 20 25 30 35 40 45 50 55 60 65 70];

%% Definindo polinomio de 1 grau
p1_l = 1.068;
p2_l = 1.314;
polinomial_1_grau = @(x) p1_l * x + p2_l;


%% Definindo polinomio de 8 grau
p1 = 5.298e-11;
p2 = -1.415e-08;
p3 = 1.553e-06;
p4 = -9.032e-05;
p5 = 0.002993;
p6 = -0.05626;
p7 = 0.5552;
p8 = -1.233;
p9 = 3.526;
polinomial_8_grau = @(x) (p1*x^8 + p2*x^7 + p3*x^6 + p4*x^5 + p5*x^4 + p6*x^3 + p7*x^2 + p8*x + p9);


%% Pontos amostrados
samples = [3.33 4.73 7.55 12.22 16.57 21.44 26.27 31.45 36.20 41.09 46.38 50.9 55.74 60.13 65.21];
n = size(samples);
n = n(2);


%% Gerando resultados da calibração com o polinimio de 1 grau
for i = 1:n
    results_pol_1_grau(i) = polinomial_1_grau(samples(i));
end

%% Gerando resultados da calibração com o polinimio de 8 grau
for i = 1:n
    results_pol_8_grau(i) = polinomial_8_grau(samples(i));
end

%% Gerando resultados da calibração com o uso das duas curvas de calibração
for i = 1:n
    if i >= 8
        results_merge(i) = polinomial_1_grau(samples(i));
    else
        results_merge(i) = polinomial_8_grau(samples(i));
    end
end

if show_plot == 1
    fplot(polinomial_1_grau, [35 70]);
    hold on
    fplot(polinomial_8_grau, [0 35]);
    grid on
    legend('Polinômio de 1° grau', 'Polinômio de 8° grau');
    title('Curva de calibração composta por dois polinomios');
    xlabel('Distância do sensor sem calibração(cm)')
    ylabel('Distância calibrada(cm)')
elseif show_plot == 2
    fplot(polinomial_1_grau, [0 70]);
    grid on
    legend('Polinômio de 1° grau');
    title('Curva de calibração polinomial de 1° grau');
    xlabel('Distância do sensor sem calibração(cm)')
    ylabel('Distância calibrada(cm)')
elseif show_plot == 3
    fplot(polinomial_8_grau, [0 70]);
    grid on
    legend('Polinômio de 8° grau');
    title('Curva de calibração polinomial de 8° grau');
    xlabel('Distância do sensor sem calibração(cm)')
    ylabel('Distância calibrada(cm)')
end

%% Calculando erros
error = 0;
error_1 = 0;
error_8 = 0;
error_merge = 0;

for i = 1:n
    error = ( samples(i) - values(i) )^2 + error;
    error_1 = ( results_pol_1_grau(i) - values(i) )^2 + error_1;
    error_8 = ( results_pol_8_grau(i) - values(i) )^2 + error_8;
    error_merge = ( results_merge(i) - values(i) )^2 + error_merge;
end

display( sqrt(error) )
display( sqrt(error_1) )
display( sqrt(error_8) )
display( sqrt(error_merge) )

error = 0;
error_1 = 0;
error_8 = 0;
error_merge = 0;

display('-----')

for i = 1:n
    error = abs( samples(i) - values(i) ) + error;
    error_1 = abs( results_pol_1_grau(i) - values(i) ) + error_1;
    error_8 = abs( results_pol_8_grau(i) - values(i) ) + error_8;
    error_merge = abs( results_merge(i) - values(i) ) + error_merge;
end

display( error )
display( error_1 )
display( error_8 )
display( error_merge )
