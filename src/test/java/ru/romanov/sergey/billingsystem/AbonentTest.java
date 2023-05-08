package ru.romanov.sergey.billingsystem;

import org.junit.jupiter.api.*;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.ResponseEntity;
import ru.romanov.sergey.billingsystem.controller.dto.callbynumber.CallByNumberResponseDTO;
import ru.romanov.sergey.billingsystem.controller.dto.callbynumber.CallDTO;
import ru.romanov.sergey.billingsystem.controller.dto.pay.PayRequestDTO;
import ru.romanov.sergey.billingsystem.controller.dto.pay.PayResponseDTO;
import ru.romanov.sergey.billingsystem.entity.Call;
import ru.romanov.sergey.billingsystem.entity.Phone;

import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;
import java.util.Objects;

import static org.assertj.core.api.Assertions.assertThat;


@SpringBootTest()
public class AbonentTest extends BaseTest{

    @Test
    @DisplayName("/abonent/pay, Mock test ")
    void abonentPaymentTest() {
        List<Call> calls = (List<Call>)callRepository.findAll();
        List<Phone> phones = (List<Phone>)phoneRepository.findAll();
        Phone phone = phones.get(0);

        System.out.println("Calls: " + calls.size());

        double prev_money = phone.getUserBalance();
        double money = 30.0;
        PayRequestDTO req = new PayRequestDTO(phone.getUserPhone(), money);
        ResponseEntity<PayResponseDTO> response = abonentController.abonentPayEndpoint(req);
        Assertions.assertTrue(response.getStatusCode().is2xxSuccessful());
        Assertions.assertEquals(
                Objects.requireNonNull(
                        response.getBody()).getMoney(),
                prev_money + money);

        phone.setUserBalance(prev_money);
        phone = phoneRepository.save(phone);

    }

    @Test
    @DisplayName("/abonent/report")
    void abonentReport(){
        List<Phone> phones = this.phoneService.findAllUsers();
        Phone phone = phones.get(0);
        List<Call> phoneCalls = phone.getCalls();
        List<CallDTO> phoneCallsDto = new ArrayList<>();
        for (int i = 0; i < phoneCalls.size(); i++) {
            Call call = phoneCalls.get(i);
            phoneCallsDto.add(new CallDTO(call.getCallType(), call.getStartTimestamp(), call.getEndTimestamp(), call.getDuration(), call.getCost()));
        }

        ResponseEntity<CallByNumberResponseDTO> response =  this.abonentController.getListCallsByNumberEndpoint(phone.getUserPhone());
        Assertions.assertTrue(response.getStatusCode().is2xxSuccessful());
        assertThat(phoneCallsDto).containsExactlyInAnyOrderElementsOf(Objects.requireNonNull(response.getBody()).getPayload());


        int minutes = 5;
        Calendar end = Calendar.getInstance();
        Calendar start = (Calendar) end.clone();
        start.add(Calendar.MINUTE, -minutes);
        Call new_call = new Call("02", phone ,new Timestamp(start.getTimeInMillis()), new Timestamp(end.getTimeInMillis()));
        callRepository.save(new_call);

        phoneCallsDto.add(new CallDTO(new_call.getCallType(), new_call.getStartTimestamp(), new_call.getEndTimestamp(), new_call.getDuration(), new_call.getCost()));

        response = this.abonentController.getListCallsByNumberEndpoint(phone.getUserPhone());
        Assertions.assertTrue(response.getStatusCode().is2xxSuccessful());
        assertThat(phoneCallsDto).containsExactlyInAnyOrderElementsOf(Objects.requireNonNull(response.getBody()).getPayload());


        callRepository.delete(new_call);
    }
}





