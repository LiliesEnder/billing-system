package ru.romanov.sergey.billingsystem;

import org.junit.jupiter.api.BeforeEach;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import ru.romanov.sergey.billingsystem.controller.AbonentController;
import ru.romanov.sergey.billingsystem.controller.ManagerController;
import ru.romanov.sergey.billingsystem.repository.*;
import ru.romanov.sergey.billingsystem.service.*;

@SpringBootTest()
public class BaseTest {
    @Autowired
    protected CallRepository callRepository;
    @Autowired
    protected PhoneRepository phoneRepository;
    @Autowired
    protected PaymentRepository paymentRepository;

    @Autowired
    protected ChangeTariffRepository changeTariffRepository;

    @Autowired
    protected TariffRepository tariffRepository;

    protected AbonentController abonentController;

    protected ManagerController managerController;

    protected PhoneService phoneService;
    protected CallService callService;
    protected PaymentService paymentService;
    protected ChangeTariffService changeTariffService;
    protected BillingService billingService;
    protected TariffService tariffService;


    @BeforeEach
    public  void initControllers(){
        phoneService = new PhoneService(phoneRepository);
        callService = new CallService(callRepository, phoneService);
        paymentService = new PaymentService(paymentRepository, phoneService);
        changeTariffService = new ChangeTariffService(changeTariffRepository);
        billingService = new BillingService(callService, phoneService);
        tariffService = new TariffService(tariffRepository);
        abonentController = new AbonentController(callService, phoneService, paymentService);
        managerController = new ManagerController(phoneService, changeTariffService, billingService, tariffService);
    }
}
