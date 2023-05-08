package ru.romanov.sergey.billingsystem;

import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.ResponseEntity;
import ru.romanov.sergey.billingsystem.controller.dto.changetariff.ChangeTariffRequestDTO;
import ru.romanov.sergey.billingsystem.controller.dto.changetariff.ChangeTariffResponseDTO;
import ru.romanov.sergey.billingsystem.entity.ChangeTariff;
import ru.romanov.sergey.billingsystem.entity.Phone;
import ru.romanov.sergey.billingsystem.entity.Tariff;

import java.util.List;
import java.util.Objects;

public class ChangeTariffTest extends BaseTest{
    @Test
    @DisplayName("/manager/change-tariff")
    void changeTariff(){
        List<Phone> phones = this.phoneService.findAllUsers();
        Phone phone = phones.get(0);
        List<Tariff> tariffs = this.tariffService.findAllTariffs();
        Tariff prev_tariff = phone.getTariff();
        Tariff tariff = null;
        for (int i = 0; i < tariffs.size(); i++) {
            if (!tariffs.get(i).equals(prev_tariff)){
                tariff = tariffs.get(i);
                break;
            }
        }
        ResponseEntity<ChangeTariffResponseDTO> response =this.managerController.postChangeTariffEndpoint(new ChangeTariffRequestDTO(phone.getUserPhone(), Objects.requireNonNull(tariff).getTariffId()));
        Assertions.assertTrue(response.getStatusCode().is2xxSuccessful());
        Assertions.assertEquals(Objects.requireNonNull(response.getBody()).getTariffId(), tariff.getTariffId());

        changeTariffService.save(new ChangeTariff(phone, prev_tariff));
    }
}
